-- Step 1: Find your user ID
-- Run this query to find your user ID in the profiles table
SELECT 
    id,
    name,
    email,
    created_at,
    mode_preferences
FROM profiles 
WHERE email IS NOT NULL 
ORDER BY created_at DESC 
LIMIT 5;

-- Step 2: Once you have your user ID, replace 'your-user-id-here' in the add_dummy_bff_profile.sql file
-- with your actual user ID, then run that file.

-- Step 3: Alternative - Quick setup with a specific user ID
-- If you know your user ID, you can run this instead:

-- Example: Replace 'your-actual-user-id' with your real user ID
/*
INSERT INTO profiles (
    id,
    name,
    age,
    location,
    bio,
    latitude,
    longitude,
    image_urls,
    mode_preferences,
    bff_enabled_at,
    bff_swipes_count,
    bff_last_active,
    created_at,
    updated_at
) VALUES (
    'bff-test-profile-001',
    'Sarah',
    26,
    'San Francisco, CA',
    'Looking for new friends to explore the city with! Love hiking, coffee, and good conversations.',
    37.7749,
    -122.4194,
    '["https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400"]',
    '{"dating": false, "bff": true}',
    NOW(),
    5,
    NOW() - INTERVAL '2 hours',
    NOW(),
    NOW()
);

-- Record that Sarah has liked you in BFF mode
INSERT INTO bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
) VALUES (
    'bff-test-profile-001',
    'your-actual-user-id',  -- Replace with your real user ID
    'like',
    NOW() - INTERVAL '1 hour'
);

-- Enable BFF mode for your profile
UPDATE profiles 
SET mode_preferences = '{"dating": true, "bff": true}',
    bff_enabled_at = NOW()
WHERE id = 'your-actual-user-id';  -- Replace with your real user ID
*/
