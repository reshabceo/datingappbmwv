-- Fix the corrupted self-match in the matches table
-- This will remove the invalid self-match and clean up the data

-- 1. First, let's see the current corrupted data
SELECT 
  'BEFORE FIX - Corrupted matches:' as status,
  id,
  user_id_1,
  user_id_2,
  status,
  created_at
FROM matches 
WHERE user_id_1 = '195cb857-3a05-4425-a6ba-3dd836ca8627' 
   OR user_id_2 = '195cb857-3a05-4425-a6ba-3dd836ca8627';

-- 2. Delete the corrupted self-match
DELETE FROM matches 
WHERE id = '4fd6beaf-a15a-4a12-8d03-b301cbaae0e2'
  AND user_id_1 = '195cb857-3a05-4425-a6ba-3dd836ca8627'
  AND user_id_2 = '195cb857-3a05-4425-a6ba-3dd836ca8627';

-- 3. Verify the fix
SELECT 
  'AFTER FIX - Remaining matches:' as status,
  id,
  user_id_1,
  user_id_2,
  status,
  created_at
FROM matches 
WHERE user_id_1 = '195cb857-3a05-4425-a6ba-3dd836ca8627' 
   OR user_id_2 = '195cb857-3a05-4425-a6ba-3dd836ca8627';

-- 4. Check if there are any other self-matches in the system
SELECT 
  'OTHER SELF-MATCHES FOUND:' as status,
  id,
  user_id_1,
  user_id_2,
  status,
  created_at
FROM matches 
WHERE user_id_1 = user_id_2;

-- 5. Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Corrupted self-match removed!';
  RAISE NOTICE '🔧 Your chat should now only show the RESHAB match';
  RAISE NOTICE '🎉 Activity feed will still work correctly';
END $$;
