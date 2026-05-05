import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import {
  create,
  getNumericDate,
} from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type PushRequest = {
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, string>;
};

type ServiceAccount = {
  client_email: string;
  private_key: string;
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleanPem = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");

  const binary = atob(cleanPem);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

async function importPrivateKey(privateKey: string): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
}

async function getGoogleAccessToken(
  serviceAccount: ServiceAccount,
): Promise<string> {
  const now = getNumericDate(0);
  const privateKey = await importPrivateKey(serviceAccount.private_key);

  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    },
    privateKey,
  );

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    throw new Error(`OAuth token exchange failed: ${errorText}`);
  }

  const tokenJson = await tokenResponse.json();
  const accessToken = tokenJson.access_token as string | undefined;

  if (!accessToken) {
    throw new Error("OAuth token response did not include access_token");
  }

  return accessToken;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!serviceAccountRaw) {
      return jsonResponse({ error: "Missing FIREBASE_SERVICE_ACCOUNT" }, 500);
    }

    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(
        { error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" },
        500,
      );
    }

    const body = await req.json() as PushRequest;

    if (!body.user_id || !body.title || !body.body) {
      return jsonResponse(
        { error: "user_id, title and body are required" },
        400,
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const serviceAccount = JSON.parse(serviceAccountRaw) as ServiceAccount;
    const { data: tokensData, error: tokensError } = await supabase
      .from("push_tokens")
      .select("token")
      .eq("user_id", body.user_id);

    if (tokensError) {
      throw tokensError;
    }

    const tokens = (tokensData ?? [])
      .map((row) => row.token as string)
      .filter((token) => typeof token === "string" && token.length > 0);

    if (tokens.length === 0) {
      return jsonResponse({ sent: false, reason: "no_tokens" });
    }

    const accessToken = await getGoogleAccessToken(serviceAccount);
    let successCount = 0;

    for (const token of tokens) {
      try {
        const sendResponse = await fetch(
          "https://fcm.googleapis.com/v1/projects/bruma-2b5d9/messages:send",
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token,
                notification: {
                  title: body.title,
                  body: body.body,
                },
                data: body.data ?? {},
                apns: {
                  payload: {
                    aps: {
                      sound: "default",
                      badge: 1,
                    },
                  },
                },
                android: {
                  priority: "high",
                },
              },
            }),
          },
        );

        if (sendResponse.ok) {
          successCount++;
          continue;
        }

        if (sendResponse.status === 404) {
          await supabase.from("push_tokens").delete().eq("token", token);
          continue;
        }

        const errorText = await sendResponse.text();
        console.error("FCM send failed", {
          token,
          status: sendResponse.status,
          errorText,
        });
      } catch (tokenError) {
        console.error("Unexpected token send error", { token, tokenError });
      }
    }

    if (successCount > 0) {
      return jsonResponse({ sent: true, count: successCount });
    }

    return jsonResponse({ sent: false, reason: "all_failed" });
  } catch (error) {
    console.error("send-push-notification failed", error);
    return jsonResponse(
      {
        sent: false,
        error: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
