-- Final Robust Match Insights Function V3
-- Handles both dating and BFF matches, legacy and modern column names, and auto-heals zodiac signs.

CREATE OR REPLACE FUNCTION public.generate_match_insights_v3(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  match_data_dating RECORD;
  match_data_bff RECORD;
  u1_id UUID;
  u2_id UUID;
  user1_data RECORD;
  user2_data RECORD;
  result JSONB;
BEGIN
  -- 1. Try dating matches
  BEGIN
    SELECT * INTO match_data_dating FROM public.matches WHERE id = p_match_id;
  EXCEPTION WHEN OTHERS THEN
    match_data_dating := NULL;
  END;
  
  IF match_data_dating.id IS NOT NULL THEN
    -- Match found in dating matches
    -- Support both user_id/other_user_id and user_id_1/user_id_2
    u1_id := COALESCE(match_data_dating.user_id, match_data_dating.user_id_1);
    u2_id := COALESCE(match_data_dating.other_user_id, match_data_dating.user_id_2);
  ELSE
    -- 2. Try BFF matches
    BEGIN
      SELECT * INTO match_data_bff FROM public.bff_matches WHERE id = p_match_id;
    EXCEPTION WHEN OTHERS THEN
      match_data_bff := NULL;
    END;
    
    IF match_data_bff.id IS NOT NULL THEN
      -- Match found in BFF matches
      u1_id := match_data_bff.user_id_1;
      u2_id := match_data_bff.user_id_2;
    END IF;
  END IF;

  -- 3. Validation
  IF u1_id IS NULL OR u2_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Match session ' || p_match_id::text || ' not found in matches or bff_matches, or participant IDs are missing.'
    );
  END IF;

  -- 4. Get participant data
  SELECT id, name, age, zodiac_sign, hobbies, location, gender, birth_date INTO user1_data FROM public.profiles WHERE id = u1_id;
  SELECT id, name, age, zodiac_sign, hobbies, location, gender, birth_date INTO user2_data FROM public.profiles WHERE id = u2_id;

  IF user1_data.id IS NULL OR user2_data.id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'User profiles missing for participants: P1=' || COALESCE(u1_id::text, 'null') || ', P2=' || COALESCE(u2_id::text, 'null')
    );
  END IF;

  -- 5. Auto-heal zodiac signs if missing but birth_date exists
  IF user1_data.zodiac_sign IS NULL AND user1_data.birth_date IS NOT NULL THEN
     user1_data.zodiac_sign := public.calculate_zodiac_sign(user1_data.birth_date);
     UPDATE public.profiles SET zodiac_sign = user1_data.zodiac_sign WHERE id = u1_id;
  END IF;
  
  IF user2_data.zodiac_sign IS NULL AND user2_data.birth_date IS NOT NULL THEN
     user2_data.zodiac_sign := public.calculate_zodiac_sign(user2_data.birth_date);
     UPDATE public.profiles SET zodiac_sign = user2_data.zodiac_sign WHERE id = u2_id;
  END IF;

  -- 6. Final Payload
  RETURN jsonb_build_object(
    'success', true,
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.generate_match_insights_v3(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_match_insights_v3(UUID) TO service_role;
