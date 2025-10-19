-- Debug SS activity to understand what's happening
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    ss_user_id UUID := 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
BEGIN
    RAISE NOTICE '--- Debug SS Activity ---';
    
    -- Check if SS has liked you in BFF mode
    RAISE NOTICE '--- 1. BFF likes from SS ---';
    PERFORM 'BFF LIKES' as activity_type, bs.action, bs.created_at
    FROM bff_swipes bs
    WHERE bs.swiper_id = ss_user_id AND bs.swiped_id = test_user_id;
    
    -- Check if you have liked SS in BFF mode
    RAISE NOTICE '--- 2. Your BFF likes to SS ---';
    PERFORM 'YOUR BFF LIKES' as activity_type, bs.action, bs.created_at
    FROM bff_swipes bs
    WHERE bs.swiper_id = test_user_id AND bs.swiped_id = ss_user_id;
    
    -- Check BFF matches between you and SS
    RAISE NOTICE '--- 3. BFF matches with SS ---';
    PERFORM 'BFF MATCHES' as activity_type, bm.status, bm.created_at
    FROM bff_matches bm
    WHERE (bm.user_id_1 = test_user_id AND bm.user_id_2 = ss_user_id)
       OR (bm.user_id_1 = ss_user_id AND bm.user_id_2 = test_user_id);
    
    -- Check what the activity function returns for SS
    RAISE NOTICE '--- 4. Activity function results for SS ---';
    PERFORM 'ACTIVITY RESULT' as activity_type, 
            other_user_name, 
            activity_type as activity_type_from_db,
            created_at,
            is_unread
    FROM get_user_activities(test_user_id, 10)
    WHERE other_user_name = 'SS';
    
END $$;
