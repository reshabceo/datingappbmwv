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

    // Get all active subscriptions that have expired
    const { data: expiredSubscriptions, error: fetchError } = await supabaseClient
      .from('user_subscriptions')
      .select('id, user_id, plan_type, end_date')
      .eq('status', 'active')
      .lt('end_date', new Date().toISOString())

    if (fetchError) {
      throw new Error('Failed to fetch expired subscriptions: ' + fetchError.message)
    }

    if (!expiredSubscriptions || expiredSubscriptions.length === 0) {
      return new Response(
        JSON.stringify({ 
          message: 'No expired subscriptions found',
          expired_count: 0 
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Update expired subscriptions
    const { error: updateError } = await supabaseClient
      .from('user_subscriptions')
      .update({
        status: 'expired',
        updated_at: new Date().toISOString(),
      })
      .eq('status', 'active')
      .lt('end_date', new Date().toISOString())

    if (updateError) {
      throw new Error('Failed to update expired subscriptions: ' + updateError.message)
    }

    // Get user IDs for profile updates
    const userIds = expiredSubscriptions.map(sub => sub.user_id)

    // Update user profiles to remove premium status
    const { error: profileError } = await supabaseClient
      .from('profiles')
      .update({
        is_premium: false,
        premium_until: null,
        updated_at: new Date().toISOString(),
      })
      .in('id', userIds)

    if (profileError) {
      throw new Error('Failed to update user profiles: ' + profileError.message)
    }

    // Track analytics events for expired subscriptions
    const analyticsEvents = expiredSubscriptions.map(sub => ({
      event_type: 'subscription_expired',
      event_data: {
        subscription_id: sub.id,
        plan_type: sub.plan_type,
        expired_at: new Date().toISOString(),
      },
      user_id: sub.user_id,
      timestamp: new Date().toISOString(),
    }))

    await supabaseClient
      .from('user_events')
      .insert(analyticsEvents)

    // Send notification emails (optional)
    await sendExpirationNotifications(supabaseClient, expiredSubscriptions)

    return new Response(
      JSON.stringify({ 
        message: 'Expired subscriptions processed successfully',
        expired_count: expiredSubscriptions.length,
        user_ids: userIds 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Subscription expiration check error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        expired_count: 0 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function sendExpirationNotifications(supabaseClient: any, expiredSubscriptions: any[]) {
  try {
    // Get user details for notifications
    const userIds = expiredSubscriptions.map(sub => sub.user_id)
    
    const { data: userProfiles } = await supabaseClient
      .from('profiles')
      .select('id, name, email')
      .in('id', userIds)

    // Here you would integrate with your email service
    // For now, we'll just log the notifications
    console.log('Sending expiration notifications to:', userProfiles?.length || 0, 'users')
    
    // Example: Send email notifications
    // await sendEmail({
    //   to: user.email,
    //   subject: 'Your Premium Subscription Has Expired',
    //   template: 'subscription-expired',
    //   data: { name: user.name }
    // })

  } catch (error) {
    console.error('Error sending expiration notifications:', error)
  }
}



