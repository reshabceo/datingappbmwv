-- Test the unified function directly with the SS match ID
-- This will help us verify the function works before redeploying the edge function

-- Test 1: Test unified function with SS match
SELECT 
    'Testing unified function with SS match' as test_name,
    generate_match_insights_unified('8ed1b38c-c962-4d77-87ed-53c46729e624') as result;

-- Test 2: Check if the old function still exists and what it returns
SELECT 
    'Testing old function with SS match' as test_name,
    generate_match_insights('8ed1b38c-c962-4d77-87ed-53c46729e624') as result;

-- Test 3: Check if the BFF-specific function works
SELECT 
    'Testing BFF function with SS match' as test_name,
    generate_bff_match_insights('8ed1b38c-c962-4d77-87ed-53c46729e624') as result;
