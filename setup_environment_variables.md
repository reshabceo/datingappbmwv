# Environment Variables Setup

## Required Razorpay Environment Variables

Set these in your Supabase project:

```bash
# Razorpay API Keys (from your Razorpay dashboard)
supabase secrets set RAZORPAY_KEY_ID=rzp_test_YOUR_KEY_ID
supabase secrets set RAZORPAY_KEY_SECRET=YOUR_SECRET_KEY

# Razorpay Webhook Secret (from webhook setup)
supabase secrets set RAZORPAY_WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET
```

## How to Get These Values:

### 1. Razorpay API Keys:
- Go to Razorpay Dashboard → Settings → API Keys
- Copy "Key ID" and "Key Secret"

### 2. Webhook Secret:
- After creating webhook in Razorpay dashboard
- Copy the "Secret" from webhook settings

## Test Your Setup:

```bash
# Deploy Edge Functions
supabase functions deploy verify-payment
supabase functions deploy razorpay-webhook
supabase functions deploy check-expired-subscriptions
supabase functions deploy send-subscription-notifications

# Test the functions
curl -X POST 'https://your-project.supabase.co/functions/v1/verify-payment' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"payment_id": "test", "order_id": "test"}'
```

## Environment Variables Status:

Check if all variables are set:
```bash
supabase secrets list
```

You should see:
- ✅ RAZORPAY_KEY_ID
- ✅ RAZORPAY_KEY_SECRET  
- ✅ RAZORPAY_WEBHOOK_SECRET

