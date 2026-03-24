-- Fix get_bff_profiles function - Minimal version with only columns that definitely exist
-- Removed: interests, bio, intent (these don't exist in your table)

-- 1. Drop the existing function
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

-- 2. Create minimal function with only existing columns
CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
  image_urls JSONB,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMP WITH TIME ZONE
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
    COALESCE(p.photos, '[]'::jsonb) as photos,
    COALESCE(p.location, '') as location,
    COALESCE(p.description, '') as description,
    COALESCE(p.hobbies, '[]'::jsonb) as hobbies,
    p.gender,
    COALESCE(p.image_urls, '[]'::jsonb) as image_urls,
    p.latitude,
    p.longitude,
    p.created_at
  FROM profiles p
  WHERE p.id != p_user_id
    -- Only check bff_enabled column
    AND p.bff_enabled = true
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
    COALESCE(p.bff_last_active, p.created_at) DESC
  LIMIT 20;
END;
$$;

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.get_bff_profiles(UUID) TO anon, authenticated;

-- 4. Test the function
SELECT 
    'Testing get_bff_profiles function' as status,
    COUNT(*) as profile_count
FROM get_bff_profiles('637f409c-c19f-490c-9183-9703473fa8e2');

-- 5. Show profiles that should be returned
SELECT 
    id,
    name,
    age,
    bff_enabled,
    created_at
FROM profiles 
WHERE bff_enabled = true
  AND id != '637f409c-c19f-490c-9183-9703473fa8e2'
LIMIT 10;

