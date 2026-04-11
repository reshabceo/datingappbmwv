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
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the call payload from request body
    const { 
      userId, 
      name, 
      username, 
      imageUrl, 
      fcmToken, 
      callType, 
      callAction, 
      notificationId, 
      webrtcRoomId, 
      matchId, 
      isBffMatch 
    } = await req.json()

    if (!fcmToken) {
      return new Response(
        JSON.stringify({ error: 'FCM token is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Send FCM notification
    const message = {
      to: fcmToken,
      notification: {
        title: `${callType === 'video' ? 'Video' : 'Audio'} Call`,
        body: `${name || username} is calling you`,
        icon: 'ic_launcher',
        sound: 'default',
      },
      data: {
        type: 'incoming_call', // Changed from 'call' to 'incoming_call'
        call_type: callType, // Sync with Flutter: caller_id, call_id, etc.
        call_id: notificationId, // Sync with Flutter
        caller_id: userId, // Sync with Flutter
        caller_name: name || username, // Sync with Flutter
        caller_image_url: imageUrl || '', // Sync with Flutter
        match_id: matchId,
        is_bff_match: isBffMatch?.toString() || 'false',
        webrtc_room_id: webrtcRoomId,
      },
      android: {
        priority: 'high',
        notification: {
          priority: 'high',
          sound: 'default',
          channelId: 'call_notifications', // Matches native channel ID
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: `${callType === 'video' ? 'Video' : 'Audio'} Call`,
              body: `${name || username} is calling you`,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
      },
    }

    // Send notification via FCM
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    })

    if (!fcmResponse.ok) {
      throw new Error(`FCM request failed: ${fcmResponse.status}`)
    }

    const fcmResult = await fcmResponse.json()
    console.log('FCM notification sent:', fcmResult)

    return new Response(
      JSON.stringify({ 
        success: true, 
        messageId: fcmResult.message_id,
        notificationId: notificationId 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error sending call notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
