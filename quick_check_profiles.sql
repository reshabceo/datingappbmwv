-- Quick check: How many profiles are available vs swiped

-- Summary counts
SELECT 
  (SELECT COUNT(*) FROM profiles WHERE id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND is_active = true) as total_active_profiles,
  (SELECT COUNT(*) FROM swipes WHERE swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b') as swiped_profiles,
  (SELECT COUNT(*) FROM matches 
   WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
     AND status IN ('matched', 'active')) as matched_profiles,
  (SELECT COUNT(*) 
   FROM profiles p
   WHERE p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
     AND p.is_active = true
     AND NOT EXISTS (
       SELECT 1 FROM swipes s2 
       WHERE s2.swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
         AND s2.swiped_id = p.id
     )
     AND NOT EXISTS (
       SELECT 1 FROM matches m 
       WHERE ((m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND m.user_id_2 = p.id)
           OR (m.user_id_1 = p.id AND m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'))
         AND m.status IN ('matched', 'active')
     )
  ) as available_profiles;

