# Cashfree Edge Function Setup Guide

## Overview
This guide explains how to deploy and configure the Cashfree webhook Edge Function for payment verification.

## Edge Function Created
- **Function Name**: `cashfree-webhook`
- **Purpose**: Handles Cashfree payment webhooks for payment verification
- **Location**: `supabase/functions/cashfree-webhook/index.ts`

## Deployment Steps

### 1. Deploy the Edge Function
```bash
# Navigate to your project directory
cd /Users/animesh/Documents/BoostMySites/datingappbmwv

# Deploy the function
supabase functions deploy cashfree-webhook
```

### 2. Configure Environment Variables
The Edge Function uses these environment variables:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key

### 3. Configure Cashfree Webhook
In your Cashfree dashboard:
1. Go to **Settings** → **Webhooks**
2. Add webhook URL: `https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/cashfree-webhook`
3. Select events:
   - `PAYMENT_SUCCESS_WEBHOOK`
   - `PAYMENT_FAILED_WEBHOOK`
4. Save the configuration

## What the Edge Function Does

### Payment Success Handling
1. **Receives webhook** from Cashfree when payment is successful
2. **Updates order status** to 'success' in `payment_orders` table
3. **Creates subscription** in `user_subscriptions` table
4. **Updates user profile** to premium status
5. **Handles subscription extension** if user already has premium

### Payment Failure Handling
1. **Receives webhook** from Cashfree when payment fails
2. **Updates order status** to 'failed' in `payment_orders` table

## Webhook Events Handled
- `PAYMENT_SUCCESS_WEBHOOK`: Payment completed successfully
- `PAYMENT_FAILED_WEBHOOK`: Payment failed or was cancelled

## Security Features
- **CORS Headers**: Properly configured for web requests
- **Error Handling**: Comprehensive error logging and handling
- **Data Validation**: Validates webhook payload structure

## Testing
1. **Sandbox Testing**: Use Cashfree sandbox environment
2. **Webhook Testing**: Use Cashfree's webhook testing tools
3. **Database Verification**: Check `payment_orders` and `user_subscriptions` tables

## Monitoring
- Check Supabase Edge Function logs for webhook processing
- Monitor database for successful order and subscription creation
- Verify user profile updates to premium status

## Troubleshooting
- **Webhook not received**: Check Cashfree webhook configuration
- **Database errors**: Verify RLS policies and table permissions
- **Subscription not created**: Check Edge Function logs for errors

## Production Checklist
- [ ] Deploy Edge Function to production
- [ ] Configure production Cashfree webhook URL
- [ ] Test with real payments (small amounts)
- [ ] Monitor logs for any errors
- [ ] Verify subscription creation works correctly
