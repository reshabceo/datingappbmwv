-- Check if Kavin and Reshab are matched
-- Kavin: ea063754-8298-4a2b-a74a-58ee274e2dcb  
-- Reshab: 7ffe44fe-9c0f-4783-aec2-a6172a6e008b

SELECT 
    'Matches between Kavin and Reshab' as check_type,
    *
FROM matches
WHERE (user_id_1 = 'ea063754-8298-4a2b-a74a-58ee274e2dcb' AND user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
   OR (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND user_id_2 = 'ea063754-8298-4a2b-a74a-58ee274e2dcb');

-- Check profiles
SELECT 'Kavin Profile' as check_type, name, email FROM profiles WHERE id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb';
SELECT 'Reshab Profile' as check_type, name, email FROM profiles WHERE id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- Check if there are any call sessions
SELECT 'Call Sessions' as check_type, * FROM call_sessions 
WHERE (caller_id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb' OR receiver_id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb')
   OR (caller_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR receiver_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY created_at DESC
LIMIT 5;

-- Check WebRTC rooms
SELECT 'WebRTC Rooms' as check_type, * FROM webrtc_rooms 
ORDER BY created_at DESC LIMIT 5;
