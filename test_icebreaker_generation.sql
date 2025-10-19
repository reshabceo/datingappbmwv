-- Test script to verify ice breaker generation is working
-- This doesn't modify the handle_swipe function, just tests the edge function

-- Check if the match_enhancements table exists and has the right structure
SELECT 'Checking match_enhancements table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'match_enhancements' 
ORDER BY ordinal_position;

-- Check if the ice_breaker_usage table exists
SELECT 'Checking ice_breaker_usage table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'ice_breaker_usage' 
ORDER BY ordinal_position;

-- Note: Edge function deployment status can be checked in the Supabase dashboard under Edge Functions

-- Check if there are any existing match enhancements
SELECT 'Checking existing match enhancements:' as info;
SELECT match_id, astro_compatibility IS NOT NULL as has_astro, ice_breakers IS NOT NULL as has_ice_breakers, expires_at, created_at
FROM match_enhancements 
LIMIT 5;

-- Check if there are any existing ice breaker usages
SELECT 'Checking existing ice breaker usage:' as info;
SELECT match_id, ice_breaker_text, used_by_user_id
FROM ice_breaker_usage 
LIMIT 5;
