-- Check if Luna has a match with the user
-- This would explain why she doesn't appear after rewind

SELECT 
  'Luna Match Check' as category,
  m.id as match_id,
  m.user_id_1,
  m.user_id_2,
  m.status,
  m.created_at,
  CASE 
    WHEN m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' THEN 'You'
    ELSE 'Luna'
  END as user_1_name,
  CASE 
    WHEN m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' THEN 'You'
    ELSE 'Luna'
  END as user_2_name
FROM matches m
WHERE (m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
   OR m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
  AND (m.user_id_1 = '11111111-aaaa-4444-8888-555555555555'
   OR m.user_id_2 = '11111111-aaaa-4444-8888-555555555555');

-- Also check if there are any swipes from Luna to you (this would create a match)
SELECT 
  'Swipes from Luna to You' as category,
  s.id as swipe_id,
  s.swiper_id,
  s.swiped_id,
  s.action,
  s.created_at
FROM swipes s
WHERE s.swiper_id = '11111111-aaaa-4444-8888-555555555555'
  AND s.swiped_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- Check if Luna should appear in discover feed (after rewind)
SELECT 
  'Should Luna Appear?' as category,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM swipes s2 
      WHERE s2.swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
        AND s2.swiped_id = '11111111-aaaa-4444-8888-555555555555'
    ) THEN '❌ NO - Has swipe'
    WHEN EXISTS (
      SELECT 1 FROM matches m 
      WHERE ((m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND m.user_id_2 = '11111111-aaaa-4444-8888-555555555555')
          OR (m.user_id_1 = '11111111-aaaa-4444-8888-555555555555' AND m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'))
        AND m.status IN ('matched', 'active')
    ) THEN '❌ NO - Has match'
    ELSE '✅ YES - Should appear'
  END as result;

