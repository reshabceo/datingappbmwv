#!/bin/bash

# Deploy the fixed generate-match-insights edge function
echo "Deploying fixed generate-match-insights edge function..."

# Navigate to the edge function directory
cd supabase/functions/generate-match-insights

# Deploy the function
supabase functions deploy generate-match-insights

echo "Edge function deployed successfully!"
echo "The fixes include:"
echo "1. Astro compatibility now explicitly mentions both zodiac signs"
echo "2. Ice breakers no longer include astrology-themed questions"
echo "3. Fallback responses are also fixed"
