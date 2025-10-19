-- WORKING FIX: Create get_bff_profiles function with correct columns
-- Based on the actual table structure we can see

-- 1. Drop the existing function
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

-- 2. Create the function with the correct columns that actually exist
CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  image_urls TEXT[],
  location TEXT,
  description TEXT,
  hobbies TEXT[],
  gender TEXT,
  photos TEXT[],
  created_at TIMESTAMP WITH TIME ZONE,
  bff_enabled BOOLEAN,
  bff_swipes_count INTEGER,
  bff_last_active TIMESTAMP WITH TIME ZONE
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
    p.image_urls,
    p.location,
    p.description,
    p.hobbies,
    p.gender,
    p.photos,
    p.created_at,
    p.bff_enabled,
    p.bff_swipes_count,
    p.bff_last_active
  FROM profiles p
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
  ORDER BY p.created_at DESC
  LIMIT 20;
END;
$$;

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.get_bff_profiles(UUID) TO anon, authenticated;

-- 4. Test the function
SELECT 
    'Testing get_bff_profiles function' as status,
    COUNT(*) as profile_count
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- 5. Show the actual profiles returned
SELECT 
    id,
    name,
    age,
    gender,
    bff_enabled,
    bff_swipes_count,
    created_at
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY created_at DESC;

-- 6. Final status
DO $$
BEGIN
  RAISE NOTICE '=== get_bff_profiles Function Fixed (WORKING) ===';
  RAISE NOTICE 'Using correct columns from actual table structure';
  RAISE NOTICE 'Function should now work correctly';
  RAISE NOTICE 'BFF profiles should be available for swiping';
END $$;
