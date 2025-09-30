import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

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
    const { type, orderId, amount, userEmail, userName, description, userId } = await req.json()

    console.log('Edge Function called with type:', type, { orderId, amount, userEmail, userId })

    // Cashfree credentials (stored as environment variables)
    const CASHFREE_APP_ID = Deno.env.get('CASHFREE_APP_ID') || 'TEST108148726e3fe406cfaf95fc00af27841801'
    const CASHFREE_SECRET_KEY = Deno.env.get('CASHFREE_SECRET_KEY') || 'cfsk_ma_test_66de59f49e4468e95026fe4777c738dc_c66ff734'
    const CASHFREE_ENVIRONMENT = Deno.env.get('CASHFREE_ENVIRONMENT') || 'sandbox'

    const baseUrl = CASHFREE_ENVIRONMENT === 'sandbox' 
        ? 'https://sandbox.cashfree.com/pg' 
        : 'https://api.cashfree.com/pg'

    if (type === 'createOrder') {
      const requestBody = {
        order_id: orderId,
        order_amount: amount, // Keep as rupees (no paise conversion)
        order_currency: 'INR',
        customer_details: {
          customer_id: userId || userEmail.replace(/[^a-zA-Z0-9_-]/g, '_'), // Use userId or sanitized email
          customer_name: userName,
          customer_email: userEmail,
          customer_phone: '9999999999', // Default phone number for Cashfree
        },
        order_meta: {
          return_url: `${req.headers.get('origin')}/payment/success`,
          notify_url: 'https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/cashfree-webhook',
        },
        order_note: description,
        payment_methods: {
          card: true,
          upi: true,
          netbanking: true,
          wallet: false,
          paylater: false,
          emi: false
        }
      }

      console.log('Calling Cashfree API for createOrder:', baseUrl)

      const response = await fetch(`${baseUrl}/orders`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': '2023-08-01',
          'x-client-id': CASHFREE_APP_ID,
          'x-client-secret': CASHFREE_SECRET_KEY,
        },
        body: JSON.stringify(requestBody),
      })

      if (response.ok) {
        const responseData = await response.json()
        console.log('Raw Cashfree API response data:', responseData)
        console.log('Cashfree payment session created:', responseData)
        
        // Debug: Check what keys are available in the response
        console.log('Available keys in Cashfree response:', Object.keys(responseData))
        
        return new Response(
          JSON.stringify({ 
            success: true, 
            payment_session_id: responseData.payment_session_id, // New API uses payment_session_id
            order_id: responseData.order_id,
            cf_order_id: responseData.cf_order_id,
            order_status: responseData.order_status,
            order_token: responseData.order_token,
            debug_response: responseData // Include full response for debugging
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200 
          }
        )
      } else {
        const errorData = await response.json()
        console.error('Cashfree API error:', errorData)
        
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: `Failed to create payment session: ${JSON.stringify(errorData)}` 
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400 
          }
        )
      }
    } else if (type === 'verifyOrder') {
      console.log('Verifying Cashfree order:', orderId)

      const response = await fetch(`${baseUrl}/orders/${orderId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': '2023-08-01',
          'x-client-id': CASHFREE_APP_ID,
          'x-client-secret': CASHFREE_SECRET_KEY,
        },
      })

      if (response.ok) {
        const responseData = await response.json()
        console.log('Cashfree order verified:', responseData)
        
        return new Response(
          JSON.stringify({ 
            success: true, 
            order_status: responseData.order_status,
            payment_status: responseData.payment_status,
            order_id: responseData.order_id,
            raw_response: responseData // Include full response for debugging
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200 
          }
        )
      } else {
        const errorData = await response.json()
        console.error('Cashfree verification error:', errorData)
        
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: `Failed to verify payment: ${JSON.stringify(errorData)}` 
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400 
          }
        )
      }
    } else {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Invalid request type. Use "createOrder" or "verifyOrder"' 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

  } catch (error) {
    console.error('Error in Cashfree Edge Function:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})