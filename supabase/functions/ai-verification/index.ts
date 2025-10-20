import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface VerificationRequest {
  userId: string;
  verificationPhotoUrl: string;
  challenge: string;
}

type VerificationResult = {
  verified?: boolean;
  confidence?: number;
  reason?: string;
  challenge_followed?: boolean;
};

console.info("verify function starting");

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { userId, verificationPhotoUrl, challenge }: VerificationRequest = await req.json();

    if (!userId || !verificationPhotoUrl || !challenge) {
      return new Response(JSON.stringify({ error: "Missing required parameters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseKey) {
      return new Response(JSON.stringify({ error: "Missing Supabase environment variables" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch profile photos
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("photos, image_urls")
      .eq("id", userId)
      .single();

    if (profileError || !profile) {
      return new Response(JSON.stringify({ error: "User profile not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userPhotos: string[] = [
      ...((profile.photos as string[] | null) ?? []),
      ...((profile.image_urls as string[] | null) ?? []),
    ].filter((p) => typeof p === "string" && p.startsWith("http"));

    if (userPhotos.length === 0) {
      return new Response(
        JSON.stringify({
          verified: false,
          reason: "No profile photos found for comparison",
          confidence: 0,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiApiKey) {
      return new Response(JSON.stringify({ error: "OpenAI API key not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const images = [
      { type: "image_url", image_url: { url: verificationPhotoUrl } },
      ...userPhotos.slice(0, 3).map((photo) => ({ type: "image_url" as const, image_url: { url: photo } })),
    ];

    const prompt = `
You are a facial verification expert. Determine if the person in the first image (verification photo) is the SAME person as in the subsequent profile photos.

VERIFICATION CHALLENGE: "${challenge}"

Important guidance:
- Focus primarily on stable facial features (face shape, bone structure, eye spacing, nose and mouth proportions).
- Allow for appearance changes like beard/no beard, makeup/no makeup, glasses on/off, hair length/style changes, lighting differences, angle and camera quality.
- Challenge compliance is helpful but NOT mandatory if face match is very strong.

Scoring policy:
- Provide a confidence 0-100 for same-person likelihood.
- If confidence ≥ 60 AND the challenge is followed, verify.
- If confidence ≥ 80, verify even if the challenge is not perfectly followed.

Return ONLY a single JSON object (no extra text) with fields:
{
  "verified": boolean,
  "confidence": number,
  "reason": string,
  "challenge_followed": boolean
}
`.trim();

    const openaiResp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [{ type: "text", text: prompt }, ...images],
          },
        ],
        max_tokens: 500,
        temperature: 0.1,
      }),
    });

    if (!openaiResp.ok) {
      const errText = await openaiResp.text().catch(() => "");
      console.error("OpenAI API error:", errText);
      return new Response(JSON.stringify({ error: "AI verification service unavailable" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const aiResult = await openaiResp.json().catch(() => null);
    const aiContent: string = aiResult?.choices?.[0]?.message?.content ?? "";

    if (!aiContent) {
      return new Response(JSON.stringify({ error: "AI verification failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Try parsing JSON directly first, fallback to regex extraction
    let verificationResult: VerificationResult = {};
    try {
      // Some models can return pure JSON; try a direct parse
      verificationResult = JSON.parse(aiContent);
    } catch {
      const jsonMatch = aiContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          verificationResult = JSON.parse(jsonMatch[0]);
        } catch {
          // leave as empty object
        }
      }
    }

    if (typeof verificationResult.verified !== "boolean") verificationResult.verified = false;
    if (typeof verificationResult.confidence !== "number") verificationResult.confidence = 0;
    if (typeof verificationResult.challenge_followed !== "boolean") verificationResult.challenge_followed = false;
    if (typeof verificationResult.reason !== "string") verificationResult.reason = "AI returned ambiguous result";

    const strongFaceMatch = (verificationResult.confidence ?? 0) >= 80;
    const goodMatchWithChallenge =
      (verificationResult.confidence ?? 0) >= 60 && (verificationResult.challenge_followed ?? false);
    const finalVerified = Boolean(verificationResult.verified) && (strongFaceMatch || goodMatchWithChallenge);
    const verificationStatus = finalVerified ? "verified" : "rejected";

    const rejectionReason = finalVerified
      ? null
      : !verificationResult.verified
      ? "Face does not match profile photos"
      : (verificationResult.confidence ?? 0) < 60
      ? "Low confidence in face match"
      : "Challenge instruction not followed";

    // Update profile immediately
    const updateProfile = supabase
      .from("profiles")
      .update({
        verification_status: verificationStatus,
        verification_photo_url: verificationPhotoUrl,
        verification_challenge: challenge,
        verification_submitted_at: new Date().toISOString(),
        verification_reviewed_at: new Date().toISOString(),
        verification_rejection_reason: rejectionReason,
        verification_confidence: verificationResult.confidence,
        verification_ai_reason: verificationResult.reason,
      })
      .eq("id", userId);

    // Log in background (won't block the response)
    const insertLog = supabase.from("verification_queue").insert({
      user_id: userId,
      challenge_text: challenge,
      verification_photo_url: verificationPhotoUrl,
      status: verificationStatus,
      reviewed_at: new Date().toISOString(),
      rejection_reason: rejectionReason,
    });

    // Ensure the critical update completes before responding
    const { error: updateErr } = await updateProfile;
    if (updateErr) {
      console.error("Profile update error:", updateErr);
    }

    // Background logging
    if ("EdgeRuntime" in globalThis && typeof (globalThis as any).EdgeRuntime?.waitUntil === "function") {
      (globalThis as any).EdgeRuntime.waitUntil(insertLog);
    } else {
      // fallback: fire and forget
      insertLog.catch((e) => console.error("verification_queue insert error:", e));
    }

    return new Response(
      JSON.stringify({
        verified: verificationResult.verified,
        confidence: verificationResult.confidence,
        reason: verificationResult.reason,
        challenge_followed: verificationResult.challenge_followed,
        status: verificationStatus,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("AI verification error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
