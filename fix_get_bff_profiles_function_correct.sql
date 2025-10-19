-- FINAL CORRECT FIX: Create get_bff_profiles function with ACTUAL columns
-- Based on the existing functions, these are the columns that actually exist

-- 1. Drop the existing function
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

-- 2. Create the correct function using actual column names
CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  photos TEXT[],
  location TEXT,
  description TEXT,
  hobbies TEXT[],
  gender TEXT,
  image_urls TEXT[],
  interests TEXT[],
  intent TEXT,
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
    p.photos,
    p.location,
    p.description,
    p.hobbies,
    p.gender,
    p.image_urls,
    p.interests,
    p.intent,
    p.created_at
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
    created_at
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY created_at DESC;

-- 6. Final status
DO $$
BEGIN
  RAISE NOTICE '=== get_bff_profiles Function Fixed (CORRECT) ===';
  RAISE NOTICE 'Using actual column names from existing functions';
  RAISE NOTICE 'Function should now work correctly';
  RAISE NOTICE 'BFF profiles should be available for swiping';
END $$;
