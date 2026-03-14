import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ZODIAC_EMOJIS = {
  "aries": "♈", "taurus": "♉", "gemini": "♊", "cancer": "♋",
  "leo": "♌", "virgo": "♍", "libra": "♎", "scorpio": "♏",
  "sagittarius": "♐", "capricorn": "♑", "aquarius": "♒", "pisces": "♓"
};

interface UserData {
  id: string;
  name: string;
  age: number;
  zodiac_sign: string;
  hobbies: string[];
  location: string;
  gender: string;
}

interface MatchData {
  match_id: string;
  user1: UserData;
  user2: UserData;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const matchId = body.matchId || body.match_id;

    if (!matchId) {
      throw new Error('Match ID is required');
    }

    const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');
    if (!OPENAI_API_KEY) {
      throw new Error('OpenAI API key not configured');
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get match data from database
    console.log(`🔍 DEBUG: Calling generate_match_insights_v5 for match: ${matchId}`);
    const { data: matchData, error: matchError } = await supabase
      .rpc('generate_match_insights_v5', { p_match_id: matchId });

    if (matchError) {
      console.error('❌ Database RPC error:', matchError);
      throw new Error(`Database error: ${matchError.message || JSON.stringify(matchError)}`);
    }

    const { user1, user2 } = matchData as MatchData;
    console.log(`✅ Participant data fetched: P1=${user1.name} (${user1.zodiac_sign}), P2=${user2.name} (${user2.zodiac_sign})`);

    // Generate Astrological Compatibility
    const sign1 = (user1.zodiac_sign || 'unknown').toLowerCase();
    const sign2 = (user2.zodiac_sign || 'unknown').toLowerCase();

    const compatibilityPrompt = `
Generate astrological compatibility analysis for two people who just matched on a dating app:

Person 1: ${user1.name}, ${sign1} ${ZODIAC_EMOJIS[sign1] || '⭐'}, Age: ${user1.age}, Gender: ${user1.gender}
Hobbies: ${user1.hobbies?.join(', ') || 'Not specified'}
Location: ${user1.location || 'Not specified'}

Person 2: ${user2.name}, ${sign2} ${ZODIAC_EMOJIS[sign2] || '⭐'}, Age: ${user2.age}, Gender: ${user2.gender}
Hobbies: ${user2.hobbies?.join(', ') || 'Not specified'}
Location: ${user2.location || 'Not specified'}

IMPORTANT: In your summary, explicitly mention both zodiac signs by name (e.g., "Your Cancer and Aries signs complement each other beautifully").

Provide a JSON response with:
{
  "compatibility_score": number (0-100),
  "summary": "Brief, romantic compatibility summary (2-3 sentences) that explicitly mentions both zodiac signs by name",
  "strengths": ["strength1", "strength2", "strength3"],
  "challenges": ["challenge1", "challenge2"],
  "romantic_outlook": "Romantic compatibility description (2-3 sentences)",
  "communication_style": "How they communicate together (1-2 sentences)",
  "advice": "Practical relationship advice based on their signs (2-3 sentences)"
}

Keep it positive, engaging, and romantic. Make it feel personal and meaningful. Focus on how their signs complement each other.
    `;

    // Generate Ice Breakers
    const iceBreakerPrompt = `
Generate 3 personalized ice breaker questions for two people who just matched on a dating app:

Person 1: ${user1.name}, Age: ${user1.age}, Gender: ${user1.gender}
Hobbies: ${user1.hobbies?.join(', ') || 'Not specified'}
Location: ${user1.location || 'Not specified'}

Person 2: ${user2.name}, Age: ${user2.age}, Gender: ${user2.gender}
Hobbies: ${user2.hobbies?.join(', ') || 'Not specified'}
Location: ${user2.location || 'Not specified'}

IMPORTANT: Do NOT include any astrology-themed questions. Focus on:
1. Their mutual interests/hobbies
2. Their locations or general lifestyle
3. General conversation starters

Provide a JSON array of exactly 3 questions:
[
  {
    "question": "Engaging, flirty question text",
    "category": "hobbies|lifestyle|general",
    "reasoning": "Why this question works for them"
  }
]

Make questions fun, flirty, and conversation-starting. Avoid generic questions and astrology references. Make them specific to their profiles and interests.
    `;

    // Call OpenAI for compatibility
    const compatibilityResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'You are an expert astrologist and relationship counselor. Your goal is to provide highly unique, specific, and varied compatibility analysis. Avoid generic or repetitive phrases. Every match should feel like a deep, custom interpretation.'
          },
          {
            role: 'user',
            content: compatibilityPrompt + "\n\nIMPORTANT: Use highly specific language. Do NOT use generic opening phrases like 'Your stars show...' or 'There is a beautiful resonance...'. Instead, dive deep into how their unique combination of traits and signs creates a one-of-a-kind dynamic."
          }
        ],
        response_format: { type: "json_object" },
        max_tokens: 1000,
        temperature: 0.9
      }),
    });

    // Call OpenAI for ice breakers
    const iceBreakerResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: 'You are a dating expert who creates engaging, personalized conversation starters based on user profiles. Always return data in the requested JSON format.' },
          { role: 'user', content: iceBreakerPrompt }
        ],
        response_format: { type: "json_object" },
        max_tokens: 800,
        temperature: 0.8
      }),
    });

    if (!compatibilityResponse.ok || !iceBreakerResponse.ok) {
      console.error('OpenAI Error:', {
        compatibility: compatibilityResponse.status,
        icebreaker: iceBreakerResponse.status
      });
      throw new Error('OpenAI API call failed');
    }

    const compatibilityData = await compatibilityResponse.json();
    const iceBreakerData = await iceBreakerResponse.json();

    let astroCompatibility, iceBreakers;

    const parseAIResponse = (content: string) => {
      try {
        // Clean markdown code blocks if present
        const cleaned = content.replace(/```json\n?|```/g, '').trim();
        return JSON.parse(cleaned);
      } catch (e) {
        console.error('Failed to parse AI response:', content);
        throw e;
      }
    };

    try {
      astroCompatibility = parseAIResponse(compatibilityData.choices[0].message.content);
    } catch (e) {
      console.error('Error parsing compatibility response:', e);
      astroCompatibility = {
        compatibility_score: 80 + Math.floor(Math.random() * 15),
        summary: `Your ${user1.zodiac_sign} and ${user2.zodiac_sign} signs show a beautiful natural resonance. There's a strong foundation for a meaningful connection here.`,
        strengths: ["Natural Understanding", "Emotional Resonance", "Shared Perspective"],
        challenges: ["Communication Nuances"],
        romantic_outlook: "High romantic potential with a focus on deep emotional sharing.",
        communication_style: "Intuitive and supportive, finding harmony in shared silence as much as conversation.",
        advice: "Focus on your shared values and give each other space to grow individually while nurturing your bond."
      };
    }

    try {
      const parsedIceBreakers = parseAIResponse(iceBreakerData.choices[0].message.content);
      // Handle both { "ice_breakers": [...] } and direct array responses
      iceBreakers = Array.isArray(parsedIceBreakers) ? parsedIceBreakers : (parsedIceBreakers.ice_breakers || parsedIceBreakers.questions || []);
    } catch (e) {
      console.error('Error parsing ice breaker response:', e);
      iceBreakers = [
        {
          question: `I noticed you both enjoy ${user1.hobbies?.[0] || 'exploring new things'} - what's your favorite local spot?`,
          category: "hobbies",
          reasoning: "Focuses on shared interests"
        },
        {
          question: "If we were to plan an ideal first outing, would you prefer something adventurous or more relaxed?",
          category: "lifestyle",
          reasoning: "Helps understand dynamic"
        },
        {
          question: "What's one thing that always makes you smile when you have a busy week?",
          category: "general",
          reasoning: "Encourages positive sharing"
        }
      ];
    }
    // Final defensive validation to ensure we never return null for these keys
    if (!astroCompatibility) {
      console.warn('⚠️ astroCompatibility was null, using emergency fallback');
      astroCompatibility = {
        compatibility_score: 85,
        summary: "Your zodiac signs create a natural harmony that promises a strong connection.",
        strengths: ["Mutual Understanding", "Shared Goals"],
        challenges: ["Minor Communication Differences"],
        romantic_outlook: "High potential for a lasting and fulfilling relationship.",
        communication_style: "Direct, honest, and supportive.",
        advice: "Be open with your feelings and enjoy the journey together."
      };
    }
    
    if (!iceBreakers || iceBreakers.length === 0) {
      console.warn('⚠️ iceBreakers was empty or null, using emergency fallback');
      iceBreakers = [
        { question: "What's the most adventurous thing you've ever done?", category: "general", reasoning: "Good ice breaker" },
        { question: "What are you most passionate about lately?", category: "general", reasoning: "Deep connection" },
        { question: "If you could travel anywhere tomorrow, where would you go?", category: "general", reasoning: "Fun topic" }
      ];
    }
    
    // Save to database with explicit onConflict to handle existing insights
    const { error: saveError } = await supabase
      .from('match_enhancements')
      .upsert({
        match_id: matchId,
        astro_compatibility: astroCompatibility,
        ice_breakers: iceBreakers,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7 days
      }, {
        onConflict: 'match_id'
      });

    if (saveError) {
      console.error('Error saving to database:', saveError);
    }

    const responseData = {
      success: true,
      astro_compatibility: astroCompatibility,
      ice_breakers: iceBreakers,
      match_id: matchId
    };

    console.log('📤 Sending response:', JSON.stringify(responseData));

    return new Response(JSON.stringify(responseData), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Error in generate-match-insights:', error);
    return new Response(JSON.stringify({
      error: error.message,
      success: false
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});