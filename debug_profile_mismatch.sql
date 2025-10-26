-- Debug profile data mismatch issue
-- Check the actual data for RESHAB and buddy profiles

-- 1. Find RESHAB's profile
SELECT 
    id,
    name,
    age,
    email,
    image_urls,
    photos,
    gender,
    description,
    hobbies
FROM profiles
WHERE email = 'reshab.retheesh@gmail.com';

-- 2. Find buddy's profile
SELECT 
    id,
    name,
    age,
    email,
    image_urls,
    photos,
    gender,
    description,
    hobbies
FROM profiles
WHERE name = 'buddy';

-- 3. Check the profile ID that the RPC is returning
-- Profile ID 7ffe44fe-9c0f-4783-aec2-a6172a6e008b (the one showing as "RESHAB")
SELECT 
    id,
    name,
    age,
    email,
    image_urls,
    photos,
    gender,
    description,
    hobbies
FROM profiles
WHERE id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 4. Check the profile ID 8fa999cb-fff7-4964-a75d-1c41574e3b4c (the one showing as "buddy")
SELECT 
    id,
    name,
    age,
    email,
    image_urls,
    photos,
    gender,
    description,
    hobbies
FROM profiles
WHERE id = '8fa999cb-fff7-4964-a75d-1c41574e3b4c';

-- 5. Look for any duplicate or orphaned profiles
SELECT 
    email,
    COUNT(*) as profile_count,
    array_agg(id) as profile_ids,
    array_agg(name) as names
FROM profiles
GROUP BY email
HAVING COUNT(*) > 1;

-- 6. Check if there are profiles with the same image URLs
SELECT 
    p1.id as profile1_id,
    p1.name as profile1_name,
    p1.email as profile1_email,
    p2.id as profile2_id,
    p2.name as profile2_name,
    p2.email as profile2_email,
    p1.image_urls
FROM profiles p1
JOIN profiles p2 ON p1.image_urls = p2.image_urls AND p1.id != p2.id
WHERE p1.image_urls IS NOT NULL;

