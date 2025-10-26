-- Query to fetch birth dates and zodiac signs for reshab and www profiles
SELECT 
    id,
    name,
    email,
    birth_date,
    zodiac_sign,
    age,
    created_at
FROM profiles 
WHERE name ILIKE '%reshab%' 
   OR name ILIKE '%www%'
   OR email ILIKE '%reshab%'
   OR email ILIKE '%kavinanup%'
ORDER BY created_at DESC;
