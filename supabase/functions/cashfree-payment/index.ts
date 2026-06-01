import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ─── PRODUCTION-ONLY CASHFREE CONFIG ────────────────────────────────────────
// Credentials are loaded from Supabase Edge Function secrets.
// Set them in Supabase dashboard → Edge Functions → cashfree-payment → Secrets:
//   CASHFREE_APP_ID     = 108566980dabe16ff7dcf1c424e9665801
//   CASHFREE_SECRET_KEY = cfsk_ma_prod_2696a352b7f5c5519d02aa8750eccfd5_5b5f2bd0
const CASHFREE_APP_ID     = Deno.env.get('CASHFREE_APP_ID')     ?? '108566980dabe16ff7dcf1c424e9665801';
const CASHFREE_SECRET_KEY = Deno.env.get('CASHFREE_SECRET_KEY') ?? 'cfsk_ma_prod_2696a352b7f5c5519d02aa8750eccfd5_5b5f2bd0';
const CASHFREE_BASE_URL   = 'https://api.cashfree.com/pg';
const CASHFREE_API_VERSION = '2023-08-01';
// ─────────────────────────────────────────────────────────────────────────────

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get the request body
    const { type, orderId, amount, userEmail, userName, description, userId, userPhone } = await req.json()

    console.log('Edge Function called with type:', type, { orderId, amount, userEmail, userId, userPhone })
    console.log('Using PRODUCTION Cashfree API:', CASHFREE_BASE_URL, '| API Version:', CASHFREE_API_VERSION)
    console.log('App ID (first 10 chars):', CASHFREE_APP_ID.substring(0, 10) + '...')

    // Validate phone number (must be 10 digits starting with 6-9 for Indian mobile)
    let phone = (userPhone || '').replace(/\D/g, '');
    if (!/^[6-9]\d{9}$/.test(phone)) {
      console.warn(`⚠️ Invalid phone "${phone}". Using fallback: 9876543210`);
      phone = '9876543210';
    }

    if (type === 'createOrder') {
      // Sanitize customer_id – must be alphanumeric, underscore, or hyphen only (max 50 chars)
      const rawCustomerId = (userId || userEmail.replace(/[^a-zA-Z0-9_-]/g, '_'));
      const customerId = rawCustomerId.substring(0, 50);

      const requestBody = {
        order_id: orderId,
        order_amount: amount,
        order_currency: 'INR',
        customer_details: {
          customer_id: customerId,
          customer_name: userName || 'User',
          customer_email: userEmail,
          customer_phone: phone,
        },
        order_meta: {
          // return_url must be whitelisted in Cashfree dashboard → Settings → Whitelisted URLs
          return_url: 'https://www.lovebug.live/payment-success?order_id={order_id}',
          notify_url: 'https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/cashfree-webhook',
        },
        order_note: description || 'LoveBug Purchase',
      }

      console.log('Creating Cashfree order:', JSON.stringify(requestBody))

      const response = await fetch(`${CASHFREE_BASE_URL}/orders`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': CASHFREE_API_VERSION,
          'x-client-id': CASHFREE_APP_ID,
          'x-client-secret': CASHFREE_SECRET_KEY,
        },
        body: JSON.stringify(requestBody),
      })

      const responseText = await response.text();
      console.log('Cashfree API response status:', response.status)
      console.log('Cashfree API response body:', responseText)

      let responseData: any;
      try {
        responseData = JSON.parse(responseText);
      } catch (e) {
        console.error('Failed to parse Cashfree response:', responseText);
        return new Response(
          JSON.stringify({ success: false, error: `Cashfree returned non-JSON response: ${responseText.substring(0, 200)}` }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

      if (response.ok) {
        console.log('✅ Cashfree order created:', JSON.stringify(responseData))
        return new Response(
          JSON.stringify({
            success: true,
            payment_session_id: responseData.payment_session_id,
            order_id: responseData.order_id,
            cf_order_id: responseData.cf_order_id,
            order_status: responseData.order_status,
            debug_response: responseData,
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      } else {
        console.error('❌ Cashfree API error:', responseData)
        return new Response(
          JSON.stringify({
            success: false,
            error: `Failed to create Cashfree order: ${JSON.stringify(responseData)}`,
            cashfree_error: responseData,
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

    } else if (type === 'verifyOrder') {
      console.log('Verifying Cashfree order:', orderId)

      const response = await fetch(`${CASHFREE_BASE_URL}/orders/${orderId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': CASHFREE_API_VERSION,
          'x-client-id': CASHFREE_APP_ID,
          'x-client-secret': CASHFREE_SECRET_KEY,
        },
      })

      const responseText = await response.text();
      console.log('Verify order response status:', response.status)
      console.log('Verify order response body:', responseText)

      let responseData: any;
      try {
        responseData = JSON.parse(responseText);
      } catch (e) {
        return new Response(
          JSON.stringify({ success: false, error: 'Failed to parse verification response' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

      if (response.ok) {
        return new Response(
          JSON.stringify({
            success: true,
            order_status: responseData.order_status,
            payment_status: responseData.payment_status,
            order_id: responseData.order_id,
            raw_response: responseData,
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      } else {
        console.error('❌ Cashfree verification error:', responseData)
        return new Response(
          JSON.stringify({ success: false, error: `Failed to verify payment: ${JSON.stringify(responseData)}` }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

    } else {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid request type. Use "createOrder" or "verifyOrder"' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

  } catch (error) {
    console.error('Error in Cashfree Edge Function:', error)
    return new Response(
      JSON.stringify({ success: false, error: `Internal server error: ${error.message}` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})