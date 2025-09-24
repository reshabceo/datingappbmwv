import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

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
    const body = await req.text()
    const signature = req.headers.get('x-razorpay-signature')
    const webhookSecret = Deno.env.get('RAZORPAY_WEBHOOK_SECRET')

    if (!signature || !webhookSecret) {
      return new Response(
        JSON.stringify({ error: 'Missing signature or webhook secret' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Verify webhook signature
    const isValidSignature = await verifyWebhookSignature(body, signature, webhookSecret)
    
    if (!isValidSignature) {
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const event = JSON.parse(body)
    console.log('Razorpay webhook event:', event.event)

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Handle different webhook events
    switch (event.event) {
      case 'payment.captured':
        await handlePaymentCaptured(supabaseClient, event.payload.payment.entity)
        break
      
      case 'payment.failed':
        await handlePaymentFailed(supabaseClient, event.payload.payment.entity)
        break
      
      case 'refund.created':
        await handleRefundCreated(supabaseClient, event.payload.refund.entity)
        break
      
      case 'subscription.charged':
        await handleSubscriptionCharged(supabaseClient, event.payload.subscription.entity)
        break
      
      default:
        console.log('Unhandled webhook event:', event.event)
    }

    return new Response(
      JSON.stringify({ 
        message: 'Webhook processed successfully',
        event: event.event 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function verifyWebhookSignature(body: string, signature: string, secret: string): Promise<boolean> {
  try {
    // Create HMAC SHA256 hash
    const encoder = new TextEncoder()
    const key = encoder.encode(secret)
    const data = encoder.encode(body)
    
    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      key,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    
    const signatureBuffer = await crypto.subtle.sign('HMAC', cryptoKey, data)
    const expectedSignature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
    
    return signature === expectedSignature
  } catch (error) {
    console.error('Signature verification error:', error)
    return false
  }
}

async function handlePaymentCaptured(supabaseClient: any, payment: any) {
  try {
    console.log('Payment captured:', payment.id)
    
    // Update payment order status
    const { error } = await supabaseClient
      .from('payment_orders')
      .update({
        status: 'success',
        payment_id: payment.id,
        updated_at: new Date().toISOString(),
      })
      .eq('payment_id', payment.id)

    if (error) {
      console.error('Error updating payment order:', error)
    }

    // Track payment success event
    await supabaseClient
      .from('user_events')
      .insert({
        event_type: 'payment_captured',
        event_data: {
          payment_id: payment.id,
          amount: payment.amount,
          currency: payment.currency,
          method: payment.method,
        },
        timestamp: new Date().toISOString(),
      })

  } catch (error) {
    console.error('Error handling payment captured:', error)
  }
}

async function handlePaymentFailed(supabaseClient: any, payment: any) {
  try {
    console.log('Payment failed:', payment.id)
    
    // Update payment order status
    const { error } = await supabaseClient
      .from('payment_orders')
      .update({
        status: 'failed',
        payment_id: payment.id,
        updated_at: new Date().toISOString(),
      })
      .eq('payment_id', payment.id)

    if (error) {
      console.error('Error updating payment order:', error)
    }

    // Track payment failure event
    await supabaseClient
      .from('user_events')
      .insert({
        event_type: 'payment_failed',
        event_data: {
          payment_id: payment.id,
          error_code: payment.error_code,
          error_description: payment.error_description,
        },
        timestamp: new Date().toISOString(),
      })

  } catch (error) {
    console.error('Error handling payment failed:', error)
  }
}

async function handleRefundCreated(supabaseClient: any, refund: any) {
  try {
    console.log('Refund created:', refund.id)
    
    // Track refund event
    await supabaseClient
      .from('user_events')
      .insert({
        event_type: 'refund_created',
        event_data: {
          refund_id: refund.id,
          payment_id: refund.payment_id,
          amount: refund.amount,
          status: refund.status,
        },
        timestamp: new Date().toISOString(),
      })

  } catch (error) {
    console.error('Error handling refund created:', error)
  }
}

async function handleSubscriptionCharged(supabaseClient: any, subscription: any) {
  try {
    console.log('Subscription charged:', subscription.id)
    
    // Handle recurring subscription charges
    // This would be used if you implement recurring subscriptions
    
    await supabaseClient
      .from('user_events')
      .insert({
        event_type: 'subscription_charged',
        event_data: {
          subscription_id: subscription.id,
          amount: subscription.amount,
          status: subscription.status,
        },
        timestamp: new Date().toISOString(),
      })

  } catch (error) {
    console.error('Error handling subscription charged:', error)
  }
}


