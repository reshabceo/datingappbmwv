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

    // Get match data from database (works for both dating and BFF matches)
    let { data: matchData, error: matchError } = await supabase
      .rpc('generate_match_insights_unified', { p_match_id: matchId });

    // If unified function fails, try the original function
    if (matchError || !matchData || matchData.error) {
      console.log('Unified function failed, trying original function...');
      const { data: fallbackData, error: fallbackError } = await supabase
        .rpc('generate_match_insights', { p_match_id: matchId });
      
      if (!fallbackError && fallbackData && !fallbackData.error) {
        matchData = fallbackData;
        matchError = null;
        console.log('Original function succeeded');
      }
    }

    if (matchError) {
      console.error('Database error:', matchError);
      throw new Error('Failed to fetch match data');
    }

    if (!matchData || matchData.error) {
      throw new Error(matchData?.error || 'Match data not found');
    }

    const { user1, user2 } = matchData as MatchData;

    // Generate Astrological Compatibility
    const compatibilityPrompt = `
Generate astrological compatibility analysis for two people who just matched on a dating app:

Person 1: ${user1.name}, ${user1.zodiac_sign} ${ZODIAC_EMOJIS[user1.zodiac_sign] || '⭐'}, Age: ${user1.age}, Gender: ${user1.gender}
Hobbies: ${user1.hobbies?.join(', ') || 'Not specified'}
Location: ${user1.location || 'Not specified'}

Person 2: ${user2.name}, ${user2.zodiac_sign} ${ZODIAC_EMOJIS[user2.zodiac_sign] || '⭐'}, Age: ${user2.age}, Gender: ${user2.gender}
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
          { role: 'system', content: 'You are an expert astrologist and relationship counselor. Provide romantic, positive compatibility analysis.' },
          { role: 'user', content: compatibilityPrompt }
        ],
        max_tokens: 1000,
        temperature: 0.7
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
          { role: 'system', content: 'You are a dating expert who creates engaging, personalized conversation starters.' },
          { role: 'user', content: iceBreakerPrompt }
        ],
        max_tokens: 800,
        temperature: 0.8
      }),
    });

    if (!compatibilityResponse.ok || !iceBreakerResponse.ok) {
      throw new Error('OpenAI API call failed');
    }

    const compatibilityData = await compatibilityResponse.json();
    const iceBreakerData = await iceBreakerResponse.json();

    let astroCompatibility, iceBreakers;

    try {
      astroCompatibility = JSON.parse(compatibilityData.choices[0].message.content);
    } catch (e) {
      console.error('Error parsing compatibility response:', e);
      astroCompatibility = {
        compatibility_score: 75,
        summary: `You two have great potential together! Your ${user1.zodiac_sign} and ${user2.zodiac_sign} signs complement each other beautifully.`,
        strengths: ["Good communication", "Shared values", "Complementary personalities"],
        challenges: ["Different approaches to life"],
        romantic_outlook: "Strong romantic potential with great chemistry",
        communication_style: "You communicate well together and understand each other",
        advice: "Take time to understand each other's perspectives and enjoy the journey together"
      };
    }

    try {
      iceBreakers = JSON.parse(iceBreakerData.choices[0].message.content);
    } catch (e) {
      console.error('Error parsing ice breaker response:', e);
      iceBreakers = [
        {
          question: "What's the most adventurous thing you've done recently?",
          category: "general",
          reasoning: "Opens up conversation about experiences"
        },
        {
          question: "I see we both enjoy similar hobbies - which one brings you the most joy?",
          category: "hobbies", 
          reasoning: "Focuses on shared interests"
        },
        {
          question: "What's your favorite way to spend a weekend?",
          category: "lifestyle",
          reasoning: "General lifestyle question to get to know each other"
        }
      ];
    }

    // Save to database
    const { error: saveError } = await supabase
      .from('match_enhancements')
      .upsert({
        match_id: matchId,
        astro_compatibility: astroCompatibility,
        ice_breakers: iceBreakers
      });

    if (saveError) {
      console.error('Error saving to database:', saveError);
      // Don't throw error, just log it
    }

    return new Response(JSON.stringify({
      success: true,
      astroCompatibility,
      iceBreakers,
      matchId
    }), {
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