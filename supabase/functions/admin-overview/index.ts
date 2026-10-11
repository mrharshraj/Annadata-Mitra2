// admin-overview: read-only aggregate counts via the service role.
// Requires a valid session AND an ADMIN_EMAILS allowlist match.
// Secrets live in function env only; never returned to callers.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function cors(req: Request): Headers {
  const origin = req.headers.get("Origin") ?? "*";
  return new Headers({
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey",
  });
}

serve(async (req) => {
  const headers = cors(req);
  headers.set("Content-Type", "application/json");
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405, headers,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const allowlist = (Deno.env.get("ADMIN_EMAILS") ?? "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
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
  const email = (user?.email ?? "").toLowerCase();
  if (!user || !email || !allowlist.includes(email)) {
    return new Response(JSON.stringify({ error: "Admin only." }), {
      status: 403, headers,
    });
  }

  const admin = createClient(supabaseUrl, serviceKey);
  const counts: Record<string, number> = {};
  for (const table of [
    "profiles", "fields", "tasks", "crop_scans", "ai_conversations",
  ]) {
    const { count, error } = await admin
      .from(table)
      .select("id", { count: "exact", head: true });
    if (error) {
      return new Response(JSON.stringify({ error: "Admin query failed." }), {
        status: 502, headers,
      });
    }
    counts[table] = count ?? 0;
  }
  return new Response(
    JSON.stringify({
      profiles: counts["profiles"],
      fields: counts["fields"],
      tasks: counts["tasks"],
      scans: counts["crop_scans"],
      conversations: counts["ai_conversations"],
    }),
    { headers },
  );
});
