// ai-chat: contextual assistant with server-side Gemini key + persistence.
// Secrets (GEMINI_API_KEY, SERVICE_ROLE_KEY) live in function env only.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent";

// Best-effort per-isolate throttle (edge isolates are ephemeral; Supabase
// Auth rate limits remain the primary abuse control).
const hits = new Map<string, number[]>();
function throttled(ip: string, limit = 20): boolean {
  const now = Date.now();
  const window = (hits.get(ip) ?? []).filter((t) => now - t < 60_000);
  if (window.length >= limit) return true;
  window.push(now);
  hits.set(ip, window);
  return false;
}

function cors(req: Request): Headers {
  const origin = req.headers.get("Origin") ?? "*";
  return new Headers({
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey",
  });
}

function systemPrompt(ctx: Record<string, unknown>): string {
  const parts = ["You are Annadata Mitra, a practical farming assistant."];
  if (ctx.farmer_name) parts.push(`Farmer: ${ctx.farmer_name}.`);
  if (ctx.village) parts.push(`Village: ${ctx.village}.`);
  if (ctx.crop) {
    parts.push(`Crop: ${ctx.crop}${ctx.crop_stage ? ` (${ctx.crop_stage})` : ""}.`);
  }
  if (ctx.weather_summary) parts.push(`Weather: ${ctx.weather_summary}.`);
  parts.push(
    `Reply in ${ctx.language === "hi" ? "Hindi" : "English"}, farmer-friendly, ` +
      "concise, actionable. State uncertainty clearly; never invent facts.",
  );
  return parts.join(" ");
}

serve(async (req) => {
  const headers = cors(req);
  headers.set("Content-Type", "application/json");
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405, headers,
    });
  }
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  if (throttled(ip)) {
    return new Response(
      JSON.stringify({ error: "Too many requests. Try again shortly." }),
      { status: 429, headers },
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return new Response(JSON.stringify({ error: "Backend not configured." }), {
      status: 503, headers,
    });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: "Invalid or expired token." }), {
      status: 401, headers,
    });
  }
  if (!geminiKey) {
    return new Response(
      JSON.stringify({ error: "AI provider not configured." }),
      { status: 503, headers },
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON." }), {
      status: 400, headers,
    });
  }
  const message = typeof body.message === "string" ? body.message.trim() : "";
  if (!message || message.length > 2000) {
    return new Response(JSON.stringify({ error: "Message must be 1-2000 chars." }), {
      status: 422, headers,
    });
  }
  const ctx = (body.context ?? {}) as Record<string, unknown>;
  const admin = createClient(supabaseUrl, serviceKey);

  let conversationId = typeof body.conversation_id === "string"
    ? (body.conversation_id as string)
    : null;
  if (conversationId) {
    const { data: owned } = await admin
      .from("ai_conversations")
      .select("id")
      .eq("id", conversationId)
      .eq("profile_id", user.id)
      .maybeSingle();
    if (!owned) {
      return new Response(JSON.stringify({ error: "Conversation not found." }), {
        status: 404, headers,
      });
    }
  } else {
    const { data: conv, error: convErr } = await admin
      .from("ai_conversations")
      .insert({ profile_id: user.id, language: ctx.language ?? "hi" })
      .select("id")
      .single();
    if (convErr || !conv) {
      return new Response(JSON.stringify({ error: "Could not start chat." }), {
        status: 502, headers,
      });
    }
    conversationId = (conv as { id: string }).id;
  }

  const geminiRes = await fetch(`${GEMINI_URL}?key=${geminiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: systemPrompt(ctx) }] },
      contents: [{ parts: [{ text: message }] }],
    }),
  });
  if (!geminiRes.ok) {
    return new Response(JSON.stringify({ error: "AI provider unavailable." }), {
      status: 503, headers,
    });
  }
  const gemini = await geminiRes.json();
  const reply: string =
    gemini?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
  if (!reply) {
    return new Response(JSON.stringify({ error: "AI returned no reply." }), {
      status: 502, headers,
    });
  }

  const { error: msgErr } = await admin.from("ai_messages").insert([
    { conversation_id: conversationId, role: "user", content: message },
    { conversation_id: conversationId, role: "assistant", content: reply },
  ]);
  if (msgErr) {
    return new Response(JSON.stringify({ error: "Could not save chat." }), {
      status: 502, headers,
    });
  }
  return new Response(
    JSON.stringify({
      reply,
      conversation_id: conversationId,
      low_confidence: false,
    }),
    { headers },
  );
});
