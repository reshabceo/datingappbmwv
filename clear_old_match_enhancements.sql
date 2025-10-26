-- Clear old match enhancements to force regeneration with new prompts
DELETE FROM match_enhancements 
WHERE match_id IN (
  SELECT id FROM matches 
  WHERE user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
     OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
);

-- Also clear any ice breaker usage tracking
DELETE FROM ice_breaker_usage 
WHERE match_id IN (
  SELECT id FROM matches 
  WHERE user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
     OR user_id_2 = '7ffe44fe-9c0f-4782-aec2-a6172a6e008b'
);
