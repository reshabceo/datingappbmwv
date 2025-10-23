# 🔧 Freemium Schema Fix Guide

## Problem
The original schema had foreign key constraint errors because it tried to reference user IDs that didn't exist yet.

## Solution
Run the clean build script that safely fixes all issues without losing data.

---

## 🚀 How to Apply the Fix

### **Step 1: Open Supabase SQL Editor**
1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**

### **Step 2: Run the Fix Script**
Copy and paste the contents of `fix_freemium_schema.sql` and run it.

Or run directly:
```bash
psql -h your-supabase-host -U postgres -d postgres -f fix_freemium_schema.sql
```

### **Step 3: Verify the Fix**
After running the script, you should see:
```
✅ Freemium schema has been cleaned and fixed successfully!
📊 All tables, constraints, functions, and policies are now properly configured.
🚀 You can now use the freemium features in your app.
```

---

## 🔍 What This Script Does

### **1. Cleans Up Existing Issues**
- ✅ Drops problematic foreign key constraints
- ✅ Removes invalid data references
- ✅ Drops conflicting policies and triggers

### **2. Rebuilds Schema Properly**
- ✅ Re-adds foreign key constraints with proper error handling
- ✅ Verifies profiles table has required columns
- ✅ Creates indexes for performance

### **3. Recreates Functions**
- ✅ `can_perform_action()` - Check if user can perform action
- ✅ `increment_daily_usage()` - Track daily usage
- ✅ `add_super_likes()` - Add super likes to user
- ✅ `activate_premium_subscription()` - Activate premium

### **4. Sets Up Security**
- ✅ Row Level Security (RLS) policies
- ✅ Proper user access controls
- ✅ Data isolation between users

---

## 📊 Tables Created/Fixed

| Table | Purpose | Foreign Keys |
|-------|---------|--------------|
| `user_daily_limits` | Track daily usage for swipes, super likes, messages | `user_id` → `profiles(id)` |
| `premium_messages` | Store messages sent before matching | `sender_id`, `recipient_id` → `profiles(id)` |
| `in_app_purchases` | Track purchases and transactions | `user_id` → `profiles(id)` |
| `premium_subscriptions` | Track premium subscription status | `user_id` → `profiles(id)` |

---

## 🧪 Testing the Fix

### **Test 1: Check if tables exist**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'user_daily_limits', 
    'premium_messages', 
    'in_app_purchases', 
    'premium_subscriptions'
  );
```

**Expected Result:** All 4 tables listed

### **Test 2: Check foreign key constraints**
```sql
SELECT
  tc.table_name,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  );
```

**Expected Result:** All foreign keys pointing to `profiles(id)`

### **Test 3: Test freemium functions**
```sql
-- Test can_perform_action function
-- Replace 'your-user-id' with an actual user ID from profiles table
SELECT can_perform_action(
  'your-user-id'::UUID,
  'swipe'
);
```

**Expected Result:** `true` or `false` based on user's premium status

### **Test 4: Test daily limit tracking**
```sql
-- Test increment_daily_usage function
-- Replace 'your-user-id' with an actual user ID
SELECT increment_daily_usage(
  'your-user-id'::UUID,
  'swipe'
);

-- Check if it was recorded
SELECT * FROM user_daily_limits 
WHERE user_id = 'your-user-id'::UUID;
```

**Expected Result:** New record created or existing record updated

---

## 🛠️ Troubleshooting

### **Issue: "relation does not exist"**
**Solution:** Make sure you ran the original `freemium_database_schema.sql` first, then run the fix script.

### **Issue: "function does not exist"**
**Solution:** The fix script recreates all functions. Just run it again.

### **Issue: "permission denied"**
**Solution:** Make sure you're running the script as a user with sufficient privileges (postgres or service_role).

### **Issue: Foreign key constraint still failing**
**Solution:** 
```sql
-- Check if there's orphaned data
SELECT user_id 
FROM user_daily_limits 
WHERE user_id NOT IN (SELECT id FROM profiles);

-- Clean it up
DELETE FROM user_daily_limits 
WHERE user_id NOT IN (SELECT id FROM profiles);
```

---

## 📱 Next Steps After Fix

### **1. Test in Your Flutter App**
```dart
// Test daily limits
final canSwipe = await SupabaseService.canPerformAction('swipe');
print('Can swipe: $canSwipe');

// Test premium status
final isPremium = await SupabaseService.isPremiumUser();
print('Is premium: $isPremium');
```

### **2. Verify Freemium Features**
- ✅ Test swipe limits for free users
- ✅ Test super like limits
- ✅ Test message restrictions
- ✅ Test profile blurring
- ✅ Test premium upgrade flow

### **3. Configure In-App Purchases**
- Set up product IDs in Google Play Console
- Set up product IDs in App Store Connect
- Test purchase flow with sandbox accounts

---

## 🎉 Success Criteria

After running the fix script successfully, you should have:

✅ All freemium tables created without errors
✅ All foreign key constraints working properly
✅ All functions created and executable
✅ All RLS policies in place
✅ All indexes created for performance
✅ No orphaned data or constraint violations

---

## 📞 Support

If you encounter any issues:
1. Check the error message carefully
2. Verify your Supabase project has the `profiles` table
3. Make sure you have the correct permissions
4. Try running the fix script again (it's idempotent)

---

## 🔒 Security Notes

- All functions use `SECURITY DEFINER` for proper access control
- RLS policies ensure users can only access their own data
- Foreign keys maintain referential integrity
- Proper indexes ensure good performance

---

**Last Updated:** October 22, 2025
**Version:** 1.0 (Clean Build Fix)
