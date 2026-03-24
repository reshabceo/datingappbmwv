-- ========================================================
-- CONSOLIDATED FIX: DISCOVERY & ASTROLOGY V2
-- ========================================================
-- This script fixes:
-- 1. "COALESCE types jsonb and text[] cannot be matched" in Astro
-- 2. "No More Dating profiles" by adding DB-level gender filtering
-- 3. Slow loading by optimizing the discovery query

-- 1. Fix Astro Compatibility RPC (v5)
-- ========================================================
DROP FUNCTION IF EXISTS public.calculate_zodiac_sign(DATE);
CREATE OR REPLACE FUNCTION public.calculate_zodiac_sign(p_birth_date DATE)
RETURNS TEXT AS $$
BEGIN
  IF p_birth_date IS NULL THEN RETURN 'unknown'; END IF;
  
  IF (extract(month from p_birth_date) = 3 AND extract(day from p_birth_date) >= 21) OR
     (extract(month from p_birth_date) = 4 AND extract(day from p_birth_date) <= 19) THEN RETURN 'aries';
  ELSIF (extract(month from p_birth_date) = 4 AND extract(day from p_birth_date) >= 20) OR
        (extract(month from p_birth_date) = 5 AND extract(day from p_birth_date) <= 20) THEN RETURN 'taurus';
  ELSIF (extract(month from p_birth_date) = 5 AND extract(day from p_birth_date) >= 21) OR
        (extract(month from p_birth_date) = 6 AND extract(day from p_birth_date) <= 20) THEN RETURN 'gemini';
  ELSIF (extract(month from p_birth_date) = 6 AND extract(day from p_birth_date) >= 21) OR
        (extract(month from p_birth_date) = 7 AND extract(day from p_birth_date) <= 22) THEN RETURN 'cancer';
  ELSIF (extract(month from p_birth_date) = 7 AND extract(day from p_birth_date) >= 23) OR
        (extract(month from p_birth_date) = 8 AND extract(day from p_birth_date) <= 22) THEN RETURN 'leo';
  ELSIF (extract(month from p_birth_date) = 8 AND extract(day from p_birth_date) >= 23) OR
        (extract(month from p_birth_date) = 9 AND extract(day from p_birth_date) <= 22) THEN RETURN 'virgo';
  ELSIF (extract(month from p_birth_date) = 9 AND extract(day from p_birth_date) >= 23) OR
        (extract(month from p_birth_date) = 10 AND extract(day from p_birth_date) <= 22) THEN RETURN 'libra';
  ELSIF (extract(month from p_birth_date) = 10 AND extract(day from p_birth_date) >= 23) OR
        (extract(month from p_birth_date) = 11 AND extract(day from p_birth_date) <= 21) THEN RETURN 'scorpio';
  ELSIF (extract(month from p_birth_date) = 11 AND extract(day from p_birth_date) >= 22) OR
        (extract(month from p_birth_date) = 12 AND extract(day from p_birth_date) <= 21) THEN RETURN 'sagittarius';
  ELSIF (extract(month from p_birth_date) = 12 AND extract(day from p_birth_date) >= 22) OR
        (extract(month from p_birth_date) = 1 AND extract(day from p_birth_date) <= 19) THEN RETURN 'capricorn';
  ELSIF (extract(month from p_birth_date) = 1 AND extract(day from p_birth_date) >= 20) OR
        (extract(month from p_birth_date) = 2 AND extract(day from p_birth_date) <= 18) THEN RETURN 'aquarius';
  ELSE RETURN 'pisces';
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS public.generate_match_insights_v4(UUID);
DROP FUNCTION IF EXISTS public.generate_match_insights_v5(UUID);
CREATE OR REPLACE FUNCTION public.generate_match_insights_v5(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  u1_id UUID;
  u2_id UUID;
  user1_record RECORD;
  user2_record RECORD;
BEGIN
  -- Get match participants
  SELECT user_id_1, user_id_2 INTO u1_id, u2_id FROM public.matches WHERE id = p_match_id;
  
  IF u1_id IS NULL THEN
     SELECT user_id_1, user_id_2 INTO u1_id, u2_id FROM public.bff_matches WHERE id = p_match_id;
  END IF;

  IF u1_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Match not found');
  END IF;

  -- Get profile data
  SELECT id, name, age, 
         COALESCE(zodiac_sign, calculate_zodiac_sign(birth_date)) as zodiac_sign, 
         hobbies, location, gender, birth_date 
  INTO user1_record FROM public.profiles WHERE id = u1_id;
  
  SELECT id, name, age, 
         COALESCE(zodiac_sign, calculate_zodiac_sign(birth_date)) as zodiac_sign, 
         hobbies, location, gender, birth_date 
  INTO user2_record FROM public.profiles WHERE id = u2_id;

  RETURN jsonb_build_object(
    'success', true,
    'user1', jsonb_build_object(
      'id', user1_record.id,
      'name', user1_record.name,
      'age', user1_record.age,
      'zodiac_sign', COALESCE(user1_record.zodiac_sign, 'unknown'),
      'hobbies', COALESCE(to_jsonb(user1_record.hobbies), '[]'::jsonb),
      'location', COALESCE(user1_record.location, 'Earth'),
      'gender', COALESCE(user1_record.gender, 'not specified')
    ),
    'user2', jsonb_build_object(
      'id', user2_record.id,
      'name', user2_record.name,
      'age', user2_record.age,
      'zodiac_sign', COALESCE(user2_record.zodiac_sign, 'unknown'),
      'hobbies', COALESCE(to_jsonb(user2_record.hobbies), '[]'::jsonb),
      'location', COALESCE(user2_record.location, 'Earth'),
      'gender', COALESCE(user2_record.gender, 'not specified')
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.generate_match_insights_v5(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_match_insights_v5(UUID) TO service_role;

-- 2. Fix Discovery RPC (get_profiles_with_super_likes_v2)
-- ========================================================
-- This version adds GENDER filtering at the SQL level to ensure we return 
-- a full page of matching profiles.

DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID, INTEGER, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes_v2(UUID, INTEGER, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);

CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes_v2(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_exclude_hours INTEGER DEFAULT 24,
  p_user_latitude DOUBLE PRECISION DEFAULT NULL,
  p_user_longitude DOUBLE PRECISION DEFAULT NULL,
  p_max_distance_km DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_preferred_gender TEXT[];
  v_min_age INTEGER;
  v_max_age INTEGER;
BEGIN
  -- Get user preferences for filtering
  SELECT preferred_gender, min_age, max_age
  INTO v_preferred_gender, v_min_age, v_max_age
  FROM public.user_preferences
  WHERE user_id = p_user_id;

  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.age,
    COALESCE(to_jsonb(p.image_urls), '[]'::jsonb) as image_urls,
    COALESCE(to_jsonb(p.photos), '[]'::jsonb) as photos,
    p.location,
    p.description,
    COALESCE(to_jsonb(p.hobbies), '[]'::jsonb) as hobbies,
    p.gender,
    p.latitude,
    p.longitude,
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) as is_super_liked
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.is_active = true
    -- Filter by preferences if they exist
    AND (
      v_preferred_gender IS NULL 
      OR cardinality(v_preferred_gender) = 0 
      OR EXISTS (
        SELECT 1 FROM unnest(v_preferred_gender) pg 
        WHERE LOWER(pg) = LOWER(p.gender)
      )
    )
    AND (v_min_age IS NULL OR p.age >= v_min_age)
    AND (v_max_age IS NULL OR p.age <= v_max_age)
    -- Exclude already swiped (within last 24h as per p_exclude_hours)
    AND NOT EXISTS (
      SELECT 1 FROM swipes s2 
      WHERE s2.swiper_id = p_user_id AND s2.swiped_id = p.id
    )
    -- Exclude matched
    AND NOT EXISTS (
      SELECT 1 FROM matches m 
      WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = p.id) OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id)
    )
    -- Distance filtering
    AND (
      p_user_latitude IS NULL OR p_user_longitude IS NULL OR p_max_distance_km IS NULL OR p_max_distance_km <= 0
      OR (
        6371.0 * 2 * asin(sqrt(power(sin(radians(p.latitude - p_user_latitude) / 2), 2) + cos(radians(p_user_latitude)) * cos(radians(p.latitude)) * power(sin(radians(p.longitude - p_user_longitude) / 2), 2)))
      ) <= p_max_distance_km
    )
  ORDER BY 
    is_super_liked DESC,
    p.created_at DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes_v2(UUID, INTEGER, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- Legacy wrappers to point to V2
CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_exclude_hours INTEGER DEFAULT 24,
  p_user_latitude DOUBLE PRECISION DEFAULT NULL,
  p_user_longitude DOUBLE PRECISION DEFAULT NULL,
  p_max_distance_km DOUBLE PRECISION DEFAULT NULL
) RETURNS SETOF RECORD AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.get_profiles_with_super_likes_v2(p_user_id, p_limit, p_exclude_hours, p_user_latitude, p_user_longitude, p_max_distance_km);
END;
$$ LANGUAGE plpgsql;
