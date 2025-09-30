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
    const body = await req.json()
    console.log('Cashfree webhook received:', body)

    // Verify the webhook signature (optional but recommended)
    const signature = req.headers.get('x-webhook-signature')
    if (!signature) {
      console.log('No signature provided')
      // In production, you should verify the signature
      // For now, we'll proceed without verification
    }

    // Extract payment details from Cashfree webhook
    const { 
      type, 
      data: { 
        order: { 
          order_id, 
          order_status, 
          order_amount, 
          order_currency,
          customer_details,
          payment_details
        } 
      } 
    } = body

    console.log('Processing webhook:', {
      type,
      order_id,
      order_status,
      order_amount,
      order_currency
    })

    // Handle different webhook types
    if (type === 'PAYMENT_SUCCESS_WEBHOOK') {
      await handlePaymentSuccess(supabaseClient, {
        order_id,
        order_status,
        order_amount,
        order_currency,
        customer_details,
        payment_details
      })
    } else if (type === 'PAYMENT_FAILED_WEBHOOK') {
      await handlePaymentFailure(supabaseClient, {
        order_id,
        order_status
      })
    } else {
      console.log('Unhandled webhook type:', type)
    }

    return new Response(
      JSON.stringify({ success: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error processing Cashfree webhook:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

async function handlePaymentSuccess(supabaseClient: any, paymentData: any) {
  const { order_id, order_status, order_amount, order_currency, customer_details, payment_details } = paymentData
  
  try {
    console.log('Handling payment success for order:', order_id)
    
    // Update order status
    const { error: orderError } = await supabaseClient
      .from('payment_orders')
      .update({
        status: 'success',
        payment_id: payment_details?.cf_payment_id || order_id,
        updated_at: new Date().toISOString(),
      })
      .eq('order_id', order_id)

    if (orderError) {
      console.error('Error updating order status:', orderError)
      return
    }

    // Get order details
    const { data: orderData, error: orderFetchError } = await supabaseClient
      .from('payment_orders')
      .select('plan_type, user_id, user_email')
      .eq('order_id', order_id)
      .single()

    if (orderFetchError) {
      console.error('Error fetching order data:', orderFetchError)
      return
    }

    // Create subscription
    await createSubscription(supabaseClient, {
      order_id,
      plan_type: orderData.plan_type,
      user_id: orderData.user_id,
      user_email: orderData.user_email,
      order_amount: order_amount
    })

    console.log('Payment success handled successfully for order:', order_id)

  } catch (error) {
    console.error('Error handling payment success:', error)
  }
}

async function handlePaymentFailure(supabaseClient: any, paymentData: any) {
  const { order_id, order_status } = paymentData
  
  try {
    console.log('Handling payment failure for order:', order_id)
    
    // Update order status
    const { error: orderError } = await supabaseClient
      .from('payment_orders')
      .update({
        status: 'failed',
        updated_at: new Date().toISOString(),
      })
      .eq('order_id', order_id)

    if (orderError) {
      console.error('Error updating order status:', orderError)
    } else {
      console.log('Order status updated to failed for order:', order_id)
    }

  } catch (error) {
    console.error('Error handling payment failure:', error)
  }
}

async function createSubscription(supabaseClient: any, subscriptionData: any) {
  const { order_id, plan_type, user_id, user_email, order_amount } = subscriptionData
  
  try {
    console.log('Creating subscription for order:', order_id)
    
    // Define subscription plans
    const subscriptionPlans = {
      '1_month': { duration_months: 1 },
      '3_month': { duration_months: 3 },
      '6_month': { duration_months: 6 }
    }
    
    const plan = subscriptionPlans[plan_type as keyof typeof subscriptionPlans]
    if (!plan) {
      console.error('Invalid plan type:', plan_type)
      return
    }
    
    const durationMonths = plan.duration_months
    const now = new Date()
    
    // Check if user already has an active subscription
    const { data: existingSubscription } = await supabaseClient
      .from('user_subscriptions')
      .select('end_date')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .order('end_date', { ascending: false })
      .limit(1)
      .single()

    let validUntil
    if (existingSubscription && existingSubscription.end_date) {
      // Extend from current end date
      const currentEndDate = new Date(existingSubscription.end_date)
      validUntil = new Date(currentEndDate.getTime() + (durationMonths * 30 * 24 * 60 * 60 * 1000))
    } else {
      // Start from now (new subscription)
      validUntil = new Date(now.getTime() + (durationMonths * 30 * 24 * 60 * 60 * 1000))
    }

    // Create subscription record
    const { error: subscriptionError } = await supabaseClient
      .from('user_subscriptions')
      .insert({
        user_id: user_id,
        plan_type: plan_type,
        status: 'active',
        start_date: now.toISOString(),
        end_date: validUntil.toISOString(),
        order_id: order_id,
        created_at: now.toISOString(),
      })

    if (subscriptionError) {
      console.error('Error creating subscription record:', subscriptionError)
      return
    }

    // Update user profile to premium
    const { error: profileError } = await supabaseClient
      .from('profiles')
      .update({
        is_premium: true,
        premium_until: validUntil.toISOString(),
      })
      .eq('id', user_id)

    if (profileError) {
      console.error('Error updating profile:', profileError)
    }

    console.log('Subscription created successfully for order:', order_id)

  } catch (error) {
    console.error('Error creating subscription:', error)
  }
}
