# Subscription Plans Setup Guide

## 🚀 Quick Setup

### Step 1: Run the SQL Script
1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `create-subscription-plans.sql`
4. Click "Run" to execute the script

### Step 2: Verify the Setup
After running the SQL script, you should see:
- `subscription_plans` table with 3 plans (Free, Premium, Premium Plus)
- `pricing_options` table with multiple duration options
- Proper RLS policies for admin access

### Step 3: Test the Integration
1. Visit `/plans` on your website
2. You should see the new pricing cards with:
   - Free plan (₹0)
   - Premium plan with 3 duration options:
     - 1 Month: ₹2,000
     - 3 Months: ₹3,000 (50% OFF) ⭐ Most Popular
     - 6 Months: ₹5,000 (58% OFF)
   - Premium Plus plan with 3 duration options

## 🔧 Admin Panel Integration

Once the database is set up:
1. Go to `/admin/subscriptions`
2. You can manage subscription plans
3. Changes will automatically reflect on the main website
4. You can add/edit pricing options and features

## 📊 Current Pricing Structure

### Free Plan
- ₹0/month
- Basic features for getting started

### Premium Plan
- **1 Month**: ₹2,000 (₹2,000/month)
- **3 Months**: ₹3,000 (₹1,000/month) - **50% OFF** ⭐ Most Popular
- **6 Months**: ₹5,000 (₹833/month) - **58% OFF**

### Premium Plus Plan
- **1 Month**: ₹5,000 (₹5,000/month)
- **3 Months**: ₹8,000 (₹2,667/month) - **47% OFF**
- **6 Months**: ₹10,000 (₹1,667/month) - **67% OFF** ⭐ Most Popular

## 🎨 Features

- **Dynamic pricing display** with savings badges
- **Interactive plan selection** with hover effects
- **Admin panel integration** for easy management
- **Responsive design** for all devices
- **Fallback to static plans** if database is unavailable

## 🐛 Troubleshooting

If you don't see the new pricing:
1. Check browser console for errors
2. Verify Supabase connection
3. Ensure the SQL script ran successfully
4. The page will fallback to static plans if database fails

## 📝 Next Steps

1. Set up payment integration (Stripe/Razorpay)
2. Add user subscription management
3. Implement checkout flow
4. Add subscription status to user profiles
