-- Fix BFF Ice Breaker Generation
-- Create BFF-specific match insights function

-- 1. Create generate_bff_match_insights function for BFF matches
CREATE OR REPLACE FUNCTION public.generate_bff_match_insights(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  match_data RECORD;
  user1_data RECORD;
  user2_data RECORD;
  result JSONB;
BEGIN
  -- Get match data from bff_matches table
  SELECT * INTO match_data FROM public.bff_matches WHERE id = p_match_id;
  
  IF match_data IS NULL THEN
    RETURN jsonb_build_object('error', 'BFF match not found');
  END IF;
  
  -- Get user profiles
  SELECT * INTO user1_data FROM public.profiles WHERE id = match_data.user_id_1;
  SELECT * INTO user2_data FROM public.profiles WHERE id = match_data.user_id_2;
  
  IF user1_data IS NULL OR user2_data IS NULL THEN
    RETURN jsonb_build_object('error', 'User profiles not found');
  END IF;
  
  -- Return user data for edge function processing
  result := jsonb_build_object(
    'match_id', p_match_id,
    'user1', jsonb_build_object(
      'id', user1_data.id,
      'name', user1_data.name,
      'age', user1_data.age,
      'zodiac_sign', user1_data.zodiac_sign,
      'hobbies', user1_data.hobbies,
      'location', user1_data.location,
      'gender', user1_data.gender
    ),
    'user2', jsonb_build_object(
      'id', user2_data.id,
      'name', user2_data.name,
      'age', user2_data.age,
      'zodiac_sign', user2_data.zodiac_sign,
      'hobbies', user2_data.hobbies,
      'location', user2_data.location,
      'gender', user2_data.gender
    )
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create a unified function that handles both dating and BFF matches
CREATE OR REPLACE FUNCTION public.generate_match_insights_unified(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  match_data RECORD;
  user1_data RECORD;
  user2_data RECORD;
  result JSONB;
BEGIN
  -- First try to find in dating matches
  SELECT * INTO match_data FROM public.matches WHERE id = p_match_id;
  
  -- If not found, try BFF matches
  IF match_data IS NULL THEN
    SELECT * INTO match_data FROM public.bff_matches WHERE id = p_match_id;
  END IF;
  
  IF match_data IS NULL THEN
    RETURN jsonb_build_object('error', 'Match not found in dating or BFF matches');
  END IF;
  
  -- Get user profiles
  SELECT * INTO user1_data FROM public.profiles WHERE id = match_data.user_id_1;
  SELECT * INTO user2_data FROM public.profiles WHERE id = match_data.user_id_2;
  
  IF user1_data IS NULL OR user2_data IS NULL THEN
    RETURN jsonb_build_object('error', 'User profiles not found');
  END IF;
  
  -- Return user data for edge function processing
  result := jsonb_build_object(
    'match_id', p_match_id,
    'user1', jsonb_build_object(
      'id', user1_data.id,
      'name', user1_data.name,
      'age', user1_data.age,
      'zodiac_sign', user1_data.zodiac_sign,
      'hobbies', user1_data.hobbies,
      'location', user1_data.location,
      'gender', user1_data.gender
    ),
    'user2', jsonb_build_object(
      'id', user2_data.id,
      'name', user2_data.name,
      'age', user2_data.age,
      'zodiac_sign', user2_data.zodiac_sign,
      'hobbies', user2_data.hobbies,
      'location', user2_data.location,
      'gender', user2_data.gender
    )
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Test the functions with your existing BFF match
-- Test the unified function with SS's match ID
SELECT 
    'Testing unified function with SS match' as test_name,
    generate_match_insights_unified('8ed1b38c-c962-4d77-87ed-53c46729e624') as result;

-- 4. Create indexes for BFF match enhancements if they don't exist
CREATE INDEX IF NOT EXISTS idx_bff_match_enhancements_match_id ON public.match_enhancements(match_id);
CREATE INDEX IF NOT EXISTS idx_bff_ice_breaker_usage_match_id ON public.ice_breaker_usage(match_id);

-- 5. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.generate_bff_match_insights(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_match_insights_unified(UUID) TO authenticated;
