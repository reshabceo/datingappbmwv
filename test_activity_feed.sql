-- Test the activity feed function to verify it's working correctly
-- This will show your matches without the extra quotes in photo URLs

SELECT 
  activity_type,
  other_user_name,
  other_user_photo,
  created_at,
  is_unread
FROM get_user_activities(
  '195cb857-3a05-4425-a6ba-3dd836ca8627'::UUID,
  50
);