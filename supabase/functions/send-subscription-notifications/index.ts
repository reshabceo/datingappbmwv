import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get subscriptions expiring in 7 days
    const { data: expiringSubscriptions, error: fetchError } = await supabaseClient
      .from('user_subscriptions')
      .select(`
        id,
        user_id,
        plan_type,
        end_date,
        profiles!inner(name)
      `)
      .eq('status', 'active')
      .gte('end_date', new Date().toISOString())
      .lte('end_date', new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString())

    if (fetchError) {
      throw new Error('Failed to fetch expiring subscriptions: ' + fetchError.message)
    }

    if (!expiringSubscriptions || expiringSubscriptions.length === 0) {
      return new Response(
        JSON.stringify({ 
          message: 'No subscriptions expiring in 7 days',
          warnings_sent: 0 
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Send warning notifications
    const warningEvents = expiringSubscriptions.map(sub => ({
      event_type: 'subscription_warning',
      event_data: {
        subscription_id: sub.id,
        plan_type: sub.plan_type,
        days_remaining: Math.ceil((new Date(sub.end_date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24)),
        end_date: sub.end_date,
        warning_type: '7_day_warning'
      },
      user_id: sub.user_id,
      timestamp: new Date().toISOString(),
    }))

    await supabaseClient
      .from('user_events')
      .insert(warningEvents)

    // Send actual notifications (you can integrate with email service here)
    await sendWarningNotifications(expiringSubscriptions)

    return new Response(
      JSON.stringify({ 
        message: 'Subscription warnings sent successfully',
        warnings_sent: expiringSubscriptions.length,
        users_notified: expiringSubscriptions.map(sub => ({
          user_id: sub.user_id,
          name: sub.profiles.name,
          days_remaining: Math.ceil((new Date(sub.end_date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))
        }))
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Subscription notification error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        warnings_sent: 0 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function sendWarningNotifications(expiringSubscriptions: any[]) {
  try {
    console.log('Sending warning notifications to:', expiringSubscriptions.length, 'users')
    
    for (const subscription of expiringSubscriptions) {
      const user = subscription.profiles
      const daysRemaining = Math.ceil((new Date(subscription.end_date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))
      
      console.log(`Warning: ${user.name} - ${daysRemaining} days remaining`)
      
      // Here you can integrate with your email service
      // Example: await sendEmail({
      //   to: user.email,
      //   subject: 'Your Premium Subscription Expires Soon',
      //   template: 'subscription-warning',
      //   data: { 
      //     name: user.name, 
      //     days_remaining: daysRemaining,
      //     plan_type: subscription.plan_type 
      //   }
      // })
    }
    
  } catch (error) {
    console.error('Error sending warning notifications:', error)
  }
}
