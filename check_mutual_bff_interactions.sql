-- Check mutual BFF interactions to debug matching issues
-- This will show us if the dummy profiles have liked the current user back

DO $$
DECLARE
    current_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    sarah_id UUID := '11111111-1111-1111-1111-111111111111';
    alex_id UUID := '22222222-2222-2222-2222-222222222222';
    emma_id UUID := '33333333-3333-3333-3333-333333333333';
BEGIN
    RAISE NOTICE '=== Checking Mutual BFF Interactions ===';
    
    -- Check interactions FROM dummy profiles TO current user
    RAISE NOTICE '--- Interactions FROM dummy profiles TO you ---';
    
    -- Sarah -> You
    RAISE NOTICE 'Sarah -> You:';
    PERFORM user_id, target_user_id, interaction_type, created_at 
    FROM bff_interactions 
    WHERE user_id = sarah_id AND target_user_id = current_user_id;
    
    -- Alex -> You  
    RAISE NOTICE 'Alex -> You:';
    PERFORM user_id, target_user_id, interaction_type, created_at 
    FROM bff_interactions 
    WHERE user_id = alex_id AND target_user_id = current_user_id;
    
    -- Emma -> You
    RAISE NOTICE 'Emma -> You:';
    PERFORM user_id, target_user_id, interaction_type, created_at 
    FROM bff_interactions 
    WHERE user_id = emma_id AND target_user_id = current_user_id;
    
    -- Check interactions FROM you TO dummy profiles
    RAISE NOTICE '--- Interactions FROM you TO dummy profiles ---';
    
    -- You -> Sarah
    RAISE NOTICE 'You -> Sarah:';
    PERFORM user_id, target_user_id, interaction_type, created_at 
    FROM bff_interactions 
    WHERE user_id = current_user_id AND target_user_id = sarah_id;
    
    -- You -> Alex
    RAISE NOTICE 'You -> Alex:';
    PERFORM user_id, target_user_id, interaction_type, created_at 
    FROM bff_interactions 
    WHERE user_id = current_user_id AND target_user_id = alex_id;
    
    -- You -> Emma
    RAISE NOTICE 'You -> Emma:';
    PERFORM user_id, target_user_id, interaction_type, created_at 
    FROM bff_interactions 
    WHERE user_id = current_user_id AND target_user_id = emma_id;
    
    -- Check for mutual interactions (both directions)
    RAISE NOTICE '--- Mutual Interactions (Both Directions) ---';
    
    -- Check Sarah mutual
    RAISE NOTICE 'Sarah Mutual Check:';
    PERFORM 
        CASE 
            WHEN EXISTS(SELECT 1 FROM bff_interactions WHERE user_id = sarah_id AND target_user_id = current_user_id AND interaction_type = 'like')
            AND EXISTS(SELECT 1 FROM bff_interactions WHERE user_id = current_user_id AND target_user_id = sarah_id AND interaction_type = 'like')
            THEN 'MUTUAL MATCH!'
            ELSE 'NO MUTUAL MATCH'
        END as sarah_status;
    
    -- Check Alex mutual
    RAISE NOTICE 'Alex Mutual Check:';
    PERFORM 
        CASE 
            WHEN EXISTS(SELECT 1 FROM bff_interactions WHERE user_id = alex_id AND target_user_id = current_user_id AND interaction_type = 'like')
            AND EXISTS(SELECT 1 FROM bff_interactions WHERE user_id = current_user_id AND target_user_id = alex_id AND interaction_type = 'like')
            THEN 'MUTUAL MATCH!'
            ELSE 'NO MUTUAL MATCH'
        END as alex_status;
    
    -- Check Emma mutual
    RAISE NOTICE 'Emma Mutual Check:';
    PERFORM 
        CASE 
            WHEN EXISTS(SELECT 1 FROM bff_interactions WHERE user_id = emma_id AND target_user_id = current_user_id AND interaction_type = 'like')
            AND EXISTS(SELECT 1 FROM bff_interactions WHERE user_id = current_user_id AND target_user_id = emma_id AND interaction_type = 'like')
            THEN 'MUTUAL MATCH!'
            ELSE 'NO MUTUAL MATCH'
        END as emma_status;

END $$;
