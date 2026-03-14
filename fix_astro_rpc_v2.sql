-- Improved Robust Match Insights Functions
-- V2: Handles auto-healing zodiac signs, BFF/Dating separation, and participant ID variants

CREATE OR REPLACE FUNCTION public.generate_match_insights_unified(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  match_data RECORD;
  u1_id UUID;
  u2_id UUID;
  user1_data RECORD;
  user2_data RECORD;
  result JSONB;
BEGIN
  -- 1. Try dating matches
  SELECT * INTO match_data FROM public.matches WHERE id = p_match_id;
  
  IF match_data.id IS NOT NULL THEN
    -- Try user_id/other_user_id (legacy) then user_id_1/user_id_2 (modern)
    u1_id := COALESCE(match_data.user_id, match_data.user_id_1);
    u2_id := COALESCE(match_data.other_user_id, match_data.user_id_2);
  ELSE
    -- 2. Try BFF matches
    SELECT * INTO match_data FROM public.bff_matches WHERE id = p_match_id;
    IF match_data.id IS NOT NULL THEN
        u1_id := match_data.user_id_1;
        u2_id := match_data.user_id_2;
    END IF;
  END IF;

  IF u1_id IS NULL OR u2_id IS NULL THEN
    RETURN jsonb_build_object('error', 'Match session not found or participant IDs missing for match: ' || p_match_id::text);
  END IF;

  -- 3. Get participant data
  SELECT id, name, age, zodiac_sign, hobbies, location, gender, birth_date INTO user1_data FROM public.profiles WHERE id = u1_id;
  SELECT id, name, age, zodiac_sign, hobbies, location, gender, birth_date INTO user2_data FROM public.profiles WHERE id = u2_id;

  IF user1_data.id IS NULL OR user2_data.id IS NULL THEN
    RETURN jsonb_build_object('error', 'User profiles missing for participants: P1=' || COALESCE(u1_id::text, 'null') || ', P2=' || COALESCE(u2_id::text, 'null'));
  END IF;

  -- 4. Auto-heal zodiac signs if missing but birth_date exists
  IF user1_data.zodiac_sign IS NULL AND user1_data.birth_date IS NOT NULL THEN
     user1_data.zodiac_sign := public.calculate_zodiac_sign(user1_data.birth_date);
     UPDATE public.profiles SET zodiac_sign = user1_data.zodiac_sign WHERE id = u1_id;
  END IF;
  
  IF user2_data.zodiac_sign IS NULL AND user2_data.birth_date IS NOT NULL THEN
     user2_data.zodiac_sign := public.calculate_zodiac_sign(user2_data.birth_date);
     UPDATE public.profiles SET zodiac_sign = user2_data.zodiac_sign WHERE id = u2_id;
  END IF;

  -- 5. Final Payload
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.generate_match_insights_unified(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_match_insights_unified(UUID) TO service_role;
