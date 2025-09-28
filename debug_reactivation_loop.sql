-- Debug the reactivation loop issue
-- Check if the is_active field is actually being updated

-- Step 1: Check Ashley's current status
SELECT 
    id,
    name,
    is_active,
    created_at,
    last_seen
FROM public.profiles 
WHERE id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- Step 2: Check if there are any RLS policies blocking the update
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles' 
AND cmd = 'UPDATE'
ORDER BY policyname;

-- Step 3: Test the update manually
UPDATE public.profiles 
SET is_active = true, last_seen = NOW()
WHERE id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- Step 4: Verify the update worked
SELECT 
    id,
    name,
    is_active,
    created_at,
    last_seen
FROM public.profiles 
WHERE id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- Step 5: Check if there are any triggers or constraints affecting the update
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';
