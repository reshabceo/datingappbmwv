import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface VerificationRequest {
  userId: string
  verificationPhotoUrl: string
  challenge: string
}

interface ProfilePhoto {
  url: string
  isPrimary: boolean
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userId, verificationPhotoUrl, challenge }: VerificationRequest = await req.json()

    if (!userId || !verificationPhotoUrl || !challenge) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get user's profile photos
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('photos, image_urls')
      .eq('id', userId)
      .single()

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: 'User profile not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get all user photos (from both photos and image_urls fields)
    const userPhotos: string[] = [
      ...(profile.photos || []),
      ...(profile.image_urls || [])
    ].filter(photo => photo && photo.startsWith('http'))

    if (userPhotos.length === 0) {
      return new Response(
        JSON.stringify({ 
          verified: false, 
          reason: 'No profile photos found for comparison',
          confidence: 0 
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Call OpenAI Vision API for face verification
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      return new Response(
        JSON.stringify({ error: 'OpenAI API key not configured' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Prepare images for OpenAI Vision API
    const images = [
      {
        type: 'image_url',
        image_url: { url: verificationPhotoUrl }
      },
      ...userPhotos.slice(0, 3).map(photo => ({
        type: 'image_url' as const,
        image_url: { url: photo }
      }))
    ]

    const prompt = `
You are a facial verification expert. I need you to determine if the person in the first image (verification photo) is the same person as in the subsequent profile photos.

VERIFICATION CHALLENGE: "${challenge}"

Instructions:
1. Look at the verification photo (first image) - the person should be following the challenge instruction
2. Compare the face in the verification photo with the faces in the profile photos
3. Consider facial features, bone structure, eye shape, nose, mouth, etc.
4. Account for different lighting, angles, expressions, and photo quality
5. The verification photo should show the person clearly following the challenge instruction

Respond with a JSON object containing:
- "verified": boolean (true if same person, false if different)
- "confidence": number (0-100, confidence in the match)
- "reason": string (brief explanation of your decision)
- "challenge_followed": boolean (whether the person followed the challenge instruction)

Be strict but fair. Only verify if you're confident it's the same person.
`

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o', // Use GPT-4o for vision capabilities
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              ...images
            ]
          }
        ],
        max_tokens: 500,
        temperature: 0.1 // Low temperature for consistent results
      })
    })

    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text()
      console.error('OpenAI API error:', errorText)
      return new Response(
        JSON.stringify({ error: 'AI verification service unavailable' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const aiResult = await openaiResponse.json()
    const aiResponse = aiResult.choices[0]?.message?.content

    if (!aiResponse) {
      return new Response(
        JSON.stringify({ error: 'AI verification failed' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Parse AI response
    let verificationResult
    try {
      // Extract JSON from AI response
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/)
      if (jsonMatch) {
        verificationResult = JSON.parse(jsonMatch[0])
      } else {
        throw new Error('No JSON found in AI response')
      }
    } catch (parseError) {
      console.error('Error parsing AI response:', parseError)
      return new Response(
        JSON.stringify({ 
          verified: false, 
          reason: 'AI response parsing failed',
          confidence: 0 
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Update user's verification status
    const verificationStatus = verificationResult.verified && 
                             verificationResult.confidence >= 70 && 
                             verificationResult.challenge_followed ? 'verified' : 'rejected'

    const rejectionReason = !verificationResult.verified ? 
      'Face does not match profile photos' : 
      !verificationResult.challenge_followed ? 
      'Challenge instruction not followed' : 
      verificationResult.confidence < 70 ? 
      'Low confidence in face match' : 
      null

    await supabase
      .from('profiles')
      .update({
        verification_status: verificationStatus,
        verification_photo_url: verificationPhotoUrl,
        verification_challenge: challenge,
        verification_submitted_at: new Date().toISOString(),
        verification_reviewed_at: new Date().toISOString(),
        verification_rejection_reason: rejectionReason,
        verification_confidence: verificationResult.confidence,
        verification_ai_reason: verificationResult.reason
      })
      .eq('id', userId)

    // Log verification attempt
    await supabase
      .from('verification_queue')
      .insert({
        user_id: userId,
        challenge_text: challenge,
        verification_photo_url: verificationPhotoUrl,
        status: verificationStatus,
        reviewed_at: new Date().toISOString(),
        rejection_reason: rejectionReason
      })

    return new Response(
      JSON.stringify({
        verified: verificationResult.verified,
        confidence: verificationResult.confidence,
        reason: verificationResult.reason,
        challenge_followed: verificationResult.challenge_followed,
        status: verificationStatus
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('AI verification error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
