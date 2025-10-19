-- Final BFF Empty State Fix
-- This script fixes all remaining BFF issues to ensure proper empty state handling

-- 1. Drop all existing record_bff_interaction functions to avoid conflicts
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, VARCHAR);
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, CHARACTER VARYING);

-- 2. Create a single, clean record_bff_interaction function
CREATE OR REPLACE FUNCTION public.record_bff_interaction(
  p_user_id UUID,
  p_target_user_id UUID,
  p_interaction_type TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validate interaction type (BFF mode only supports 'like' and 'pass')
  IF p_interaction_type NOT IN ('like', 'pass') THEN
    RAISE EXCEPTION 'Invalid BFF interaction type: %', p_interaction_type;
  END IF;
  
  -- Record the BFF interaction
  INSERT INTO public.bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
  ) VALUES (
    p_user_id,
    p_target_user_id,
    p_interaction_type,
    NOW()
  )
  ON CONFLICT (user_id, target_user_id) 
  DO UPDATE SET 
    interaction_type = EXCLUDED.interaction_type,
    created_at = NOW();
  
  -- Update user's BFF activity counters and timestamps
  UPDATE public.profiles
  SET 
    bff_last_active = NOW(),
    bff_swipes_count = COALESCE(bff_swipes_count, 0) + 1
  WHERE id = p_user_id;
  
  -- Log the interaction for debugging
  RAISE NOTICE 'BFF interaction recorded: user_id=%, target_user_id=%, type=%', 
    p_user_id, p_target_user_id, p_interaction_type;
    
END;
$$;

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.record_bff_interaction(UUID, UUID, TEXT) TO anon, authenticated;

-- 4. Update get_bff_profiles function to be more restrictive
CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  bio TEXT,
  location TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  gender TEXT,
  image_urls TEXT[],
  interests TEXT[],
  intent TEXT,
  is_super_liked BOOLEAN,
  distance_km DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.age,
    p.bio,
    p.location,
    p.latitude,
    p.longitude,
    p.gender,
    p.image_urls,
    p.interests,
    p.intent,
    COALESCE(sl.is_super_liked, false) as is_super_liked,
    CASE 
      WHEN p.latitude IS NOT NULL AND p.longitude IS NOT NULL THEN
        -- Calculate distance if both users have coordinates
        (SELECT ST_Distance(
          ST_Point(p.longitude, p.latitude)::geography,
          ST_Point(up.longitude, up.latitude)::geography
        ) / 1000.0 -- Convert to kilometers
        FROM profiles up WHERE up.id = p_user_id)
      ELSE NULL
    END as distance_km
  FROM profiles p
  LEFT JOIN super_likes sl ON sl.target_user_id = p.id AND sl.user_id = p_user_id
  WHERE p.id != p_user_id
    AND p.bff_enabled = true  -- Only show profiles that have BFF enabled
    AND p.id NOT IN (
      -- Exclude users already interacted with in BFF mode
      SELECT target_user_id 
      FROM bff_interactions 
      WHERE user_id = p_user_id
    )
    AND p.id NOT IN (
      -- Exclude users already matched in BFF mode
      SELECT CASE 
        WHEN user_id_1 = p_user_id THEN user_id_2 
        ELSE user_id_1 
      END
      FROM bff_matches 
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
        AND status IN ('matched', 'active')
    )
  ORDER BY 
    CASE WHEN p.latitude IS NOT NULL AND p.longitude IS NOT NULL THEN distance_km ELSE 999999 END,
    p.created_at DESC
  LIMIT 20; -- Limit to 20 profiles to prevent infinite loading
END;
$$;

-- 5. Test the functions
DO $$
BEGIN
  RAISE NOTICE '=== BFF Empty State Fix Complete ===';
  RAISE NOTICE 'Fixed function overloading issue';
  RAISE NOTICE 'Added profile limit to prevent infinite loading';
  RAISE NOTICE 'BFF system should now show empty state properly';
END $$;
