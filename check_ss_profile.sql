-- Check SS's profile data to see if they have photos
SELECT 
    id,
    name,
    photos,
    image_urls,
    created_at
FROM profiles 
WHERE name ILIKE '%ss%' OR name ILIKE '%SS%'
ORDER BY created_at DESC;
