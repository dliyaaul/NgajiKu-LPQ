
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

function readDefaultKey(
  legacyName: string,
  collectionName: string,
): string | undefined {
  const legacy = Deno.env.get(legacyName);
  if (legacy) return legacy;

  const raw = Deno.env.get(collectionName);
  if (!raw) return undefined;

  try {
    const parsed = JSON.parse(raw);
    return typeof parsed.default === "string"
      ? parsed.default
      : undefined;
  } catch {
    return undefined;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authorization = req.headers.get("Authorization");

  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { pertemuan_id?: unknown };

  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body" }, 400);
  }

  const pertemuanId = body.pertemuan_id;

  if (
    typeof pertemuanId !== "string" ||
    pertemuanId.trim().length === 0 ||
    pertemuanId.length > 100
  ) {
    return json({ error: "Invalid pertemuan_id" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = readDefaultKey(
    "SUPABASE_ANON_KEY",
    "SUPABASE_PUBLISHABLE_KEYS",
  );
  const serviceRoleKey = readDefaultKey(
    "SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_SECRET_KEYS",
  );
  const webUrl = Deno.env.get("ATTENDANCE_WEB_URL");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("Required Supabase configuration is missing.");
    return json({ error: "Backend configuration is incomplete" }, 500);
  }

  if (!webUrl) {
    return json({ error: "Web URL has not been configured yet" }, 503);
  }

  let redirectUrl: URL;

  try {
    redirectUrl = new URL(webUrl);

    const isLocalhost =
      redirectUrl.hostname === "localhost" ||
      redirectUrl.hostname === "127.0.0.1";

    if (
      redirectUrl.username ||
      redirectUrl.password ||
      (redirectUrl.protocol !== "https:" &&
        !(isLocalhost && redirectUrl.protocol === "http:"))
    ) {
      return json({ error: "Invalid Web URL configuration" }, 500);
    }
  } catch {
    return json({ error: "Invalid Web URL configuration" }, 500);
  }

  try {
    // Validasi sesi pengguna melalui Supabase Auth.
    const userClient = createClient(supabaseUrl, anonKey, {
      global: {
        headers: { Authorization: authorization },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user || !user.email) {
      return json({ error: "Invalid user session" }, 401);
    }

    // Client administratif hanya digunakan di sisi server.
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    // Hanya admin yang diizinkan melakukan handoff.
    const { data: profile, error: profileError } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    if (profileError) {
      console.error("Role lookup failed:", profileError.message);
      return json({ error: "Could not verify access permission" }, 500);
    }

    if (profile?.role !== "admin") {
      return json({ error: "Forbidden" }, 403);
    }

    // Pastikan pertemuan yang diminta memang ada.
    const { data: pertemuan, error: pertemuanError } =
      await adminClient
        .from("bbaq_pertemuan")
        .select("id")
        .eq("id", pertemuanId)
        .maybeSingle();

    if (pertemuanError) {
      console.error("Meeting lookup failed:", pertemuanError.message);
      return json({ error: "Could not verify meeting" }, 500);
    }

    if (!pertemuan) {
      return json({ error: "BBAQ meeting not found" }, 404);
    }

    // Pertahankan URL web yang dikonfigurasi dan tambahkan konteks pertemuan.
    redirectUrl.searchParams.set("pertemuan_id", pertemuanId);

    const { data, error } = await adminClient.auth.admin.generateLink({
      type: "magiclink",
      email: user.email,
      options: {
        redirectTo: redirectUrl.toString(),
      },
    });

    if (error || !data.properties?.action_link) {
      console.error("Magic link generation failed:", error?.message);
      return json({ error: "Could not create a web sign-in link" }, 500);
    }

    // Jangan catat action_link ke log.
    return json({ action_url: data.properties.action_link });
  } catch (error) {
    console.error(
      "Handoff error:",
      error instanceof Error ? error.message : "Unknown error",
    );

    return json({ error: "Internal server error" }, 500);
  }
});
