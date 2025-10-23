# 🚀 Quick Start: Freemium System Setup

## Option 1: Using Supabase SQL Editor (Recommended)

### **Step 1: Open Supabase Dashboard**
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **SQL Editor** in the left sidebar

### **Step 2: Run the Fix Script**
1. Click **New Query**
2. Copy the entire contents of `fix_freemium_schema.sql`
3. Paste into the SQL editor
4. Click **Run** button

✅ **Expected Result:** You should see success messages and no errors

### **Step 3: Verify Setup**
1. Click **New Query** again
2. Copy the entire contents of `verify_freemium_setup.sql`
3. Paste into the SQL editor
4. Click **Run** button

✅ **Expected Result:** You should see all tables, functions, and policies listed with ✅ status

---

## Option 2: Using Command Line (Advanced)

### **Prerequisites:**
- `psql` command-line tool installed
- Supabase database connection string

### **Step 1: Set Database URL**
```bash
export SUPABASE_DB_URL="postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres"
```

### **Step 2: Run Deployment Script**
```bash
cd /Users/reshab/Desktop/datingappbmwv
./deploy_freemium.sh
```

✅ **Expected Result:** Script completes with success message

---

## What Gets Created?

### **Tables:**
- ✅ `user_daily_limits` - Track daily swipes, super likes, messages
- ✅ `premium_messages` - Store messages sent before matching
- ✅ `in_app_purchases` - Track purchases and transactions
- ✅ `premium_subscriptions` - Track premium subscription status

### **Functions:**
- ✅ `can_perform_action()` - Check if user can perform action
- ✅ `increment_daily_usage()` - Increment daily usage counters
- ✅ `add_super_likes()` - Add purchased super likes
- ✅ `activate_premium_subscription()` - Activate premium subscription

### **Security:**
- ✅ Row Level Security (RLS) policies
- ✅ Foreign key constraints
- ✅ Indexes for performance
- ✅ Triggers for auto-updates

---

## Troubleshooting

### ❌ **Error: "relation does not exist"**
**Fix:** Run `freemium_database_schema.sql` first, then run the fix script

### ❌ **Error: "foreign key constraint violation"**
**Fix:** The `fix_freemium_schema.sql` script handles this automatically

### ❌ **Error: "permission denied"**
**Fix:** Make sure you're using the service_role key or postgres user

---

## Testing in Flutter

After successful deployment, test in your Flutter app:

```dart
import 'package:lovebug/services/supabase_service.dart';

// Test daily limits
final canSwipe = await SupabaseService.canPerformAction('swipe');
print('Can swipe: $canSwipe');

// Test premium status
final isPremium = await SupabaseService.isPremiumUser();
print('Is premium: $isPremium');

// Get daily usage
final usage = await SupabaseService.getDailyUsage();
print('Swipes used: ${usage['swipes_used']}');
```

---

## Next Steps

1. ✅ **Test Freemium Features**
   - Test swipe limits
   - Test super like limits
   - Test message restrictions
   - Test profile blurring

2. ✅ **Configure In-App Purchases**
   - Set up products in Google Play Console
   - Set up products in App Store Connect
   - Test purchase flow

3. ✅ **Deploy to Production**
   - Test thoroughly in staging
   - Deploy to production
   - Monitor usage and analytics

---

## Support

If you need help:
1. Check `FREEMIUM_FIX_GUIDE.md` for detailed troubleshooting
2. Run `verify_freemium_setup.sql` to check what's missing
3. Review error messages carefully

---

**Ready to go? Run the fix script now!** 🚀
