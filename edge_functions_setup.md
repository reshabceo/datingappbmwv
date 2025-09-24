# 🚀 Supabase Edge Functions Setup Guide

## 📋 **OVERVIEW**

This guide covers the deployment and configuration of Supabase Edge Functions for Razorpay payment integration, subscription management, and automatic expiration handling.

---

## 🛠️ **EDGE FUNCTIONS DEPLOYED**

### **1. verify-payment**
- **Purpose**: Server-side payment verification with Razorpay API
- **Endpoint**: `/functions/v1/verify-payment`
- **Method**: POST
- **Body**: `{ "payment_id": "pay_xxx", "order_id": "order_xxx" }`

### **2. check-expired-subscriptions**
- **Purpose**: Check and expire subscriptions automatically
- **Endpoint**: `/functions/v1/check-expired-subscriptions`
- **Method**: POST
- **Returns**: Count of expired subscriptions

### **3. razorpay-webhook**
- **Purpose**: Handle Razorpay webhook events
- **Endpoint**: `/functions/v1/razorpay-webhook`
- **Method**: POST
- **Events**: payment.captured, payment.failed, refund.created

---

## 🚀 **DEPLOYMENT STEPS**

### **Step 1: Install Supabase CLI**
```bash
npm install -g supabase
```

### **Step 2: Login to Supabase**
```bash
supabase login
```

### **Step 3: Link to Your Project**
```bash
supabase link --project-ref dkcitxzvojvecuvacwsp
```

### **Step 4: Deploy Edge Functions**
```bash
# Deploy all functions
supabase functions deploy

# Or deploy individual functions
supabase functions deploy verify-payment
supabase functions deploy check-expired-subscriptions
supabase functions deploy razorpay-webhook
```

### **Step 5: Set Environment Variables**
```bash
# Set Razorpay credentials
supabase secrets set RAZORPAY_KEY_ID=rzp_live_YOUR_KEY_ID
supabase secrets set RAZORPAY_KEY_SECRET=YOUR_SECRET_KEY
supabase secrets set RAZORPAY_WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET

# Set Supabase credentials (usually auto-configured)
supabase secrets set SUPABASE_URL=https://dkcitxzvojvecuvacwsp.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

---

## 🗄️ **DATABASE SETUP**

### **Step 1: Run Database Schema**
Execute the following SQL files in your Supabase SQL Editor:

1. **subscription_schema.sql** - Core subscription tables
2. **expiration_functions.sql** - Database functions for expiration

### **Step 2: Enable Extensions**
```sql
-- Enable pg_cron for scheduled jobs (optional)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule automatic expiration check (runs every hour)
SELECT cron.schedule('check-expired-subscriptions', '0 * * * *', 'SELECT check_and_expire_subscriptions();');
```

---

## 🔧 **CONFIGURATION**

### **Razorpay Dashboard Setup**

#### **1. Webhook Configuration**
- **URL**: `https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/razorpay-webhook`
- **Events**: 
  - `payment.captured`
  - `payment.failed`
  - `refund.created`
  - `subscription.charged`

#### **2. API Keys**
- Get your **Key ID** and **Key Secret** from Razorpay Dashboard
- Update environment variables in Supabase

#### **3. Webhook Secret**
- Generate a webhook secret in Razorpay Dashboard
- Set as `RAZORPAY_WEBHOOK_SECRET` in Supabase

---

## 🧪 **TESTING**

### **Test Payment Verification**
```bash
curl -X POST 'https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/verify-payment' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "payment_id": "pay_test_xxx",
    "order_id": "order_xxx"
  }'
```

### **Test Expiration Check**
```bash
curl -X POST 'https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/check-expired-subscriptions' \
  -H 'Authorization: Bearer YOUR_ANON_KEY'
```

### **Test Webhook**
```bash
curl -X POST 'https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/razorpay-webhook' \
  -H 'Content-Type: application/json' \
  -H 'x-razorpay-signature: YOUR_SIGNATURE' \
  -d '{
    "event": "payment.captured",
    "payload": {
      "payment": {
        "entity": {
          "id": "pay_test_xxx",
          "status": "captured"
        }
      }
    }
  }'
```

---

## 📊 **MONITORING**

### **Function Logs**
```bash
# View function logs
supabase functions logs verify-payment
supabase functions logs check-expired-subscriptions
supabase functions logs razorpay-webhook
```

### **Database Monitoring**
```sql
-- Check subscription analytics
SELECT * FROM get_subscription_analytics();

-- View subscription dashboard
SELECT * FROM subscription_dashboard;

-- Check expired subscriptions
SELECT * FROM check_and_expire_subscriptions();
```

---

## 🔒 **SECURITY**

### **RLS Policies**
All tables have Row Level Security enabled:
- Users can only access their own data
- Service role has full access for functions
- Webhook endpoints are secured with signature verification

### **API Security**
- All functions require proper authentication
- Razorpay webhook signature verification
- CORS headers configured for web access

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues**

#### **1. Function Deployment Fails**
```bash
# Check function status
supabase functions list

# View deployment logs
supabase functions logs --follow
```

#### **2. Payment Verification Fails**
- Check Razorpay API credentials
- Verify webhook URL configuration
- Check function logs for errors

#### **3. Subscription Not Expiring**
- Verify cron job is scheduled
- Check database function execution
- Monitor function logs

### **Debug Commands**
```bash
# Test function locally
supabase functions serve

# Check environment variables
supabase secrets list

# View function details
supabase functions describe verify-payment
```

---

## 📈 **PERFORMANCE OPTIMIZATION**

### **Database Indexes**
```sql
-- Optimize subscription queries
CREATE INDEX CONCURRENTLY idx_user_subscriptions_status_end_date 
ON user_subscriptions(status, end_date) 
WHERE status = 'active';

-- Optimize profile queries
CREATE INDEX CONCURRENTLY idx_profiles_premium_until 
ON profiles(premium_until) 
WHERE is_premium = TRUE;
```

### **Function Optimization**
- Functions are optimized for minimal execution time
- Database queries use proper indexing
- Error handling prevents function timeouts

---

## 🎯 **PRODUCTION CHECKLIST**

### **Before Going Live**
- [ ] Deploy all Edge Functions
- [ ] Set production Razorpay credentials
- [ ] Configure webhook URLs
- [ ] Test payment flow end-to-end
- [ ] Set up monitoring and alerts
- [ ] Configure backup strategies

### **Post-Deployment**
- [ ] Monitor function performance
- [ ] Check subscription expiration accuracy
- [ ] Verify payment verification
- [ ] Monitor error rates
- [ ] Set up automated backups

---

## 🎉 **READY FOR PRODUCTION**

Your Razorpay payment integration is now fully configured with:

✅ **Server-side payment verification**  
✅ **Automatic subscription expiration**  
✅ **Webhook event handling**  
✅ **Database function optimization**  
✅ **Security and monitoring**  
✅ **Production-ready deployment**  

The system will automatically handle payment verification, subscription management, and expiration without manual intervention!



