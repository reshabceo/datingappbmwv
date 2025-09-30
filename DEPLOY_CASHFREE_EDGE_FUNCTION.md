# 🚀 Deploy Cashfree Edge Function

## **Step 1: Deploy the Edge Function**

Run this command in your terminal:

```bash
cd /Users/animesh/Documents/BoostMySites/datingappbmwv
supabase functions deploy cashfree-payment
```

## **Step 2: Set Environment Variables**

Set the Cashfree credentials as environment variables:

```bash
supabase secrets set CASHFREE_APP_ID=TEST108148726e3fe406cfaf95fc00af27841801
supabase secrets set CASHFREE_SECRET_KEY=cfsk_ma_test_66de59f49e4468e95026fe4777c738dc_c66ff734
supabase secrets set CASHFREE_ENVIRONMENT=sandbox
```

## **Step 3: Test the Function**

After deployment, test it:

```bash
supabase functions serve cashfree-payment
```

## **Step 4: Update Your App**

The payment service is already updated to use the Edge Function. Just refresh your browser and try the payment again.

## **What This Fixes:**

✅ **CORS Error**: Edge Function runs on server, no CORS issues  
✅ **Security**: API keys are server-side, not exposed to browser  
✅ **Cashfree Integration**: Direct API calls to Cashfree from server  
✅ **No Razorpay**: Only Cashfree payment methods enabled  

## **If You Get Errors:**

1. **Function not found**: Make sure you deployed it first
2. **Environment variables**: Make sure you set the secrets
3. **CORS still**: Clear browser cache and hard refresh

The Edge Function will handle all Cashfree API calls securely from the server side!
