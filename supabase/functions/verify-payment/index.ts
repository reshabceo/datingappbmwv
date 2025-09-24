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
    const { payment_id, order_id } = await req.json()

    if (!payment_id || !order_id) {
      return new Response(
        JSON.stringify({ error: 'Missing payment_id or order_id' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Verify payment with Razorpay
    const razorpayResponse = await fetch('https://api.razorpay.com/v1/payments/' + payment_id, {
      method: 'GET',
      headers: {
        'Authorization': 'Basic ' + btoa(Deno.env.get('RAZORPAY_KEY_ID') + ':' + Deno.env.get('RAZORPAY_KEY_SECRET')),
        'Content-Type': 'application/json',
      },
    })

    if (!razorpayResponse.ok) {
      throw new Error('Failed to verify payment with Razorpay')
    }

    const paymentData = await razorpayResponse.json()

    // Check if payment is successful
    if (paymentData.status !== 'captured') {
      return new Response(
        JSON.stringify({ 
          verified: false, 
          error: 'Payment not captured',
          status: paymentData.status 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Update order status in database
    const { error: updateError } = await supabaseClient
      .from('payment_orders')
      .update({
        status: 'success',
        payment_id: payment_id,
        updated_at: new Date().toISOString(),
      })
      .eq('order_id', order_id)

    if (updateError) {
      throw new Error('Failed to update order status: ' + updateError.message)
    }

    // Get order details
    const { data: orderData, error: orderError } = await supabaseClient
      .from('payment_orders')
      .select('plan_type, user_id, amount')
      .eq('order_id', order_id)
      .single()

    if (orderError || !orderData) {
      throw new Error('Order not found')
    }

    // Create subscription
    const subscriptionResult = await createSubscription(
      supabaseClient,
      orderData.user_id,
      orderData.plan_type,
      order_id
    )

    if (!subscriptionResult.success) {
      throw new Error('Failed to create subscription: ' + subscriptionResult.error)
    }

    return new Response(
      JSON.stringify({ 
        verified: true, 
        payment_id: payment_id,
        subscription_id: subscriptionResult.subscription_id 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Payment verification error:', error)
    return new Response(
      JSON.stringify({ 
        verified: false, 
        error: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function createSubscription(supabaseClient: any, userId: string, planType: string, orderId: string) {
  try {
    // Define plan durations
    const planDurations = {
      '1_month': 30,
      '3_month': 90,
      '6_month': 180
    }

    const durationDays = planDurations[planType as keyof typeof planDurations] || 30
    const now = new Date()
    const endDate = new Date(now.getTime() + (durationDays * 24 * 60 * 60 * 1000))

    // Create subscription record
    const { data: subscriptionData, error: subscriptionError } = await supabaseClient
      .from('user_subscriptions')
      .insert({
        user_id: userId,
        plan_type: planType,
        status: 'active',
        start_date: now.toISOString(),
        end_date: endDate.toISOString(),
        order_id: orderId,
        created_at: now.toISOString(),
      })
      .select('id')
      .single()

    if (subscriptionError) {
      return { success: false, error: subscriptionError.message }
    }

    // Update user profile to premium
    const { error: profileError } = await supabaseClient
      .from('profiles')
      .update({
        is_premium: true,
        premium_until: endDate.toISOString(),
        updated_at: now.toISOString(),
      })
      .eq('id', userId)

    if (profileError) {
      return { success: false, error: profileError.message }
    }

    // Track analytics event
    await supabaseClient
      .from('user_events')
      .insert({
        event_type: 'subscription_created',
        event_data: {
          plan_type: planType,
          subscription_id: subscriptionData.id,
          order_id: orderId,
        },
        user_id: userId,
        timestamp: now.toISOString(),
      })

    return { 
      success: true, 
      subscription_id: subscriptionData.id 
    }

  } catch (error) {
    return { 
      success: false, 
      error: error.message 
    }
  }
}



