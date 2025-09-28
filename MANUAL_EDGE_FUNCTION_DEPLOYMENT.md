# Manual Edge Function Deployment Guide

Since the Supabase project is in another account, here's how to manually deploy the Edge Function:

## **Step 1: Access Supabase Dashboard**

1. Go to: `https://supabase.com/dashboard/project/dkcitxzvojvecuvacwsp`
2. Log in with the account that has access to this project

## **Step 2: Create Edge Function**

1. In the Supabase Dashboard, go to **Edge Functions** in the left sidebar
2. Click **"Create a new function"**
3. Name it: `generate-match-insights`
4. Copy the entire content from `/Users/darshanrk/datingappbmwv/supabase/functions/generate-match-insights/index.ts`
5. Paste it into the function editor
6. Click **"Deploy"**

## **Step 3: Set Environment Variables**

1. Go to **Settings** → **Edge Functions** → **Secrets**
2. Add the following secret:
   - **Key**: `OPENAI_API_KEY`
   - **Value**: `your_openai_api_key_here`

## **Step 4: Test the Function**

Once deployed, test it with:

```bash
curl -X POST 'https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/generate-match-insights' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"matchId": "YOUR_MATCH_ID"}'
```

## **Expected Response:**

```json
{
  "success": true,
  "astroCompatibility": {
    "compatibility_score": 85,
    "summary": "Great astrological compatibility!",
    "strengths": ["communication", "values"],
    "challenges": ["different approaches"],
    "romantic_outlook": "Strong potential",
    "advice": "Take time to understand each other"
  },
  "iceBreakers": [
    {
      "question": "What's your favorite adventure?",
      "category": "hobbies",
      "reasoning": "Based on shared interests"
    }
  ]
}
```

## **Alternative: Use Database Function Instead**

If you can't deploy the Edge Function, the app will fall back to using the database function `generate_match_insights` which is already working. The astro features will still work, just without the AI-generated content.

---

**Once the Edge Function is deployed, the astrological compatibility features will be fully functional!** 🌟
