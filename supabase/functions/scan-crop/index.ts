// scan-crop: vision analysis with server-side Gemini key + persistence.
// Validates upload, checks storage-prefix + field ownership, writes the
// crop_scans row. Secrets live in function env only.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent";

const ALLOWED_MIME = new Set(["image/jpeg", "image/png", "image/webp"]);
const MAX_BYTES = 8 * 1024 * 1024;

const hits = new Map<string, number[]>();
function throttled(ip: string, limit = 10): boolean {
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

function parseReply(text: string): {
  crop: string | null;
  issue: string | null;
  confidence: number;
  notes: string;
} {
  let crop: string | null = null;
  let issue: string | null = null;
  let notes: string | null = null;
  let confidence = 0;
  for (const line of text.split("\n")) {
    const sep = line.indexOf(":");
    if (sep < 0) continue;
    const key = line.slice(0, sep).trim().toUpperCase();
    const val = line.slice(sep + 1).trim();
    if (key === "CROP") crop = val || null;
    else if (key === "ISSUE") {
      issue = /^none/i.test(val) ? null : val || null;
    } else if (key === "CONFIDENCE") {
      const n = Number(val);
      confidence = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0;
    } else if (key === "NEXT") notes = val || null;
  }
  return {
    crop, issue, confidence,
    notes: notes ?? "Consult a local agronomist to confirm.",
  };
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

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON." }), {
      status: 400, headers,
    });
  }
  const imagePath = typeof body.image_path === "string" ? body.image_path : "";
  const fieldId = typeof body.field_id === "string" ? body.field_id : null;
  if (!imagePath || imagePath.length > 500) {
    return new Response(JSON.stringify({ error: "image_path required." }), {
      status: 422, headers,
    });
  }
  if (imagePath !== user.id && !imagePath.startsWith(`${user.id}/`)) {
    return new Response(JSON.stringify({ error: "Not your image." }), {
      status: 403, headers,
    });
  }

  const admin = createClient(supabaseUrl, serviceKey);
  if (fieldId) {
    const { data: own } = await admin
      .from("fields")
      .select("id")
      .eq("id", fieldId)
      .eq("profile_id", user.id)
      .maybeSingle();
    if (!own) {
      return new Response(JSON.stringify({ error: "Field not found." }), {
        status: 404, headers,
      });
    }
  }

  const { data: blob, error: dlErr } = await admin.storage
    .from("crop-scans")
    .download(imagePath);
  if (dlErr || !blob) {
    return new Response(JSON.stringify({ error: "Could not fetch image." }), {
      status: 502, headers,
    });
  }
  const mime = blob.type || "image/jpeg";
  const bytes = new Uint8Array(await blob.arrayBuffer());
  if (!ALLOWED_MIME.has(mime)) {
    return new Response(
      JSON.stringify({ error: `Unsupported image type: ${mime}.` }),
      { status: 400, headers },
    );
  }
  if (bytes.length === 0 || bytes.length > MAX_BYTES) {
    return new Response(
      JSON.stringify({ error: "Image must be non-empty and under 8 MB." }),
      { status: 400, headers },
    );
  }
  if (!geminiKey) {
    return new Response(
      JSON.stringify({ error: "Vision analysis not configured." }),
      { status: 503, headers },
    );
  }

  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  const geminiRes = await fetch(`${GEMINI_URL}?key=${geminiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      system_instruction: {
        parts: [{
          text: "You are a plant pathologist assistant. Look at this crop photo and reply with: most likely crop, most likely visible issue (or 'none visible'), a confidence score between 0 and 1, and one practical next step. If unsure, say so and keep confidence below 0.5. Format: CROP: ... ISSUE: ... CONFIDENCE: ... NEXT: ...",
        }],
      },
      contents: [{
        parts: [{ inline_data: { mime_type: mime, data: btoa(binary) } }],
      }],
    }),
  });
  if (!geminiRes.ok) {
    return new Response(JSON.stringify({ error: "Vision provider unavailable." }), {
      status: 503, headers,
    });
  }
  const gemini = await geminiRes.json();
  const text: string =
    gemini?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
  if (!text) {
    return new Response(JSON.stringify({ error: "Vision returned no result." }), {
      status: 502, headers,
    });
  }
  const parsed = parseReply(text);
  const { data: row, error: insErr } = await admin
    .from("crop_scans")
    .insert({
      profile_id: user.id,
      field_id: fieldId,
      image_path: imagePath,
      detected_crop: parsed.crop,
      detected_issue: parsed.issue,
      confidence: parsed.confidence,
      analysis: { notes: parsed.notes },
      status: "done",
    })
    .select("id")
    .single();
  if (insErr || !row) {
    return new Response(JSON.stringify({ error: "Could not save scan." }), {
      status: 502, headers,
    });
  }
  return new Response(
    JSON.stringify({
      scan_id: (row as { id: string }).id,
      detected_crop: parsed.crop,
      detected_issue: parsed.issue,
      confidence: parsed.confidence,
      notes: parsed.notes,
    }),
    { headers },
  );
});
