-- OVERLOAD WRAPPER: Match app's expected RPC signature
-- The Flutter app calls get_profiles_with_super_likes(p_limit, p_user_id)
-- This wrapper delegates to the fixed single-arg function and applies LIMIT

-- Ensure the single-arg version exists (created in fix_matching_system_final.sql)
-- CREATE OR REPLACE FUNCTION get_profiles_with_super_likes(p_user_id UUID) ...

-- Create two-parameter overload to satisfy RPC call with p_limit and p_user_id
CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_limit INTEGER,
  p_user_id UUID,
  p_exclude_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INT,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM get_profiles_with_super_likes(p_user_id) gp
  WHERE NOT EXISTS (
    SELECT 1
    FROM swipes s
    WHERE s.swiper_id = p_user_id
      AND s.swiped_id = gp.id
      AND s.created_at > (now() - ((p_exclude_hours || ' hours')::interval))
  )
  LIMIT COALESCE(p_limit, 50);
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(INTEGER, UUID, INTEGER) TO anon, authenticated;

-- Quick test calls (run in SQL editor):
-- SELECT COUNT(*) FROM public.get_profiles_with_super_likes(50, '00000000-0000-0000-0000-000000000000'::uuid);
-- SELECT name, age, is_super_liked FROM public.get_profiles_with_super_likes(10, '00000000-0000-0000-0000-000000000000'::uuid) LIMIT 5;


