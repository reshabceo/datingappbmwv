-- Fix the get_bff_profiles function to match actual table schema
-- Drop and recreate the function with correct types

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS get_bff_profiles(uuid);

-- Create the corrected function
CREATE OR REPLACE FUNCTION get_bff_profiles(p_user_id UUID)
RETURNS TABLE(
    id UUID,
    name TEXT,
    age INTEGER,
    photos JSONB,
    location TEXT,
    description TEXT,
    hobbies JSONB,
    is_super_liked BOOLEAN,
    bff_swipes_count INTEGER,
    bff_last_active TIMESTAMP WITH TIME ZONE
) AS $$
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
        EXISTS(
            SELECT 1 FROM bff_interactions bi
            WHERE bi.user_id = p_user_id
            AND bi.target_user_id = p.id
            AND bi.interaction_type = 'super_like'
        ) as is_super_liked,
        p.bff_swipes_count,
        p.bff_last_active
    FROM profiles p
    WHERE p.id != p_user_id
    AND p.mode_preferences->>'bff' = 'true'
    AND p.bff_swipes_count > 0  -- Only show users who have been active in BFF
    AND p.id NOT IN (
        SELECT target_user_id
        FROM bff_interactions
        WHERE user_id = p_user_id
    )
    ORDER BY p.bff_last_active DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT * FROM get_bff_profiles('c1ffb3e0-0e25-4176-9736-0db8522fd357');
