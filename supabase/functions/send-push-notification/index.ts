import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  userId: string
  type: 'new_match' | 'new_message' | 'new_like' | 'story_reply' | 'account_suspended' | 'admin_message' | 'incoming_call' | 'missed_call' | 'call_ended' | 'call_rejected' | 'clear_notification'
  title: string
  body: string
  data?: Record<string, any>
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📱 PUSH: Edge function called');
    const { userId, type, title, body, data = {} }: NotificationRequest = await req.json()
    console.log('📱 PUSH: Request data:', { userId, type, title, body, data });

    if (!userId || !type || !title || !body) {
      console.log('❌ PUSH: Missing required fields');
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get user's FCM token and notification preferences
    console.log('📱 PUSH: Fetching user profile for userId:', userId);
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token, notification_matches, notification_messages, notification_stories, notification_likes, notification_admin')
      .eq('id', userId)
      .single()

    if (profileError || !profile) {
      console.log('❌ PUSH: User not found:', profileError);
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    console.log('📱 PUSH: User profile found, FCM token exists:', !!profile.fcm_token);
    console.log('📱 PUSH: FCM token (first 20 chars):', profile.fcm_token ? profile.fcm_token.substring(0, 20) + '...' : 'null');

    // Check if user has FCM token
    if (!profile.fcm_token) {
      console.log('❌ PUSH: User has no FCM token');
      return new Response(
        JSON.stringify({ error: 'User has no FCM token' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Check notification preferences
    const notificationKey = `notification_${type.replace('new_', '').replace('_', '')}`
    if (profile[notificationKey] === false) {
      return new Response(
        JSON.stringify({ message: 'Notification disabled by user preference' }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Send push notification via Firebase V1 API
    const firebaseProjectId = 'lovebug-dating-app'
    const firebasePrivateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')
    const firebaseClientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
    
    if (!firebasePrivateKey || !firebaseClientEmail) {
      return new Response(
        JSON.stringify({ error: 'Firebase configuration missing. Need FIREBASE_PRIVATE_KEY and FIREBASE_CLIENT_EMAIL' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Get access token for Firebase V1 API
    const accessToken = await getFirebaseAccessToken(firebasePrivateKey, firebaseClientEmail, firebaseProjectId)
    
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`
    
    // Determine if this is a call notification for special handling
    const isCallNotification = ['incoming_call', 'missed_call', 'call_ended', 'call_rejected'].includes(type)
    const isClearNotification = type === 'clear_notification'
    console.log('📱 PUSH: Is call notification:', isCallNotification);
    console.log('📱 PUSH: Is clear notification:', isClearNotification);
    console.log('📱 PUSH: Call type from data:', data.call_type);
    
    // Build notification message with platform-specific handling
    // Ensure all data values are strings (FCM requirement)
    const stringifiedData: Record<string, string> = {}
    Object.entries(data).forEach(([key, value]) => {
      stringifiedData[key] = String(value ?? '')
    })
    stringifiedData['type'] = type
    
    // CRITICAL FIX: Include caller name in notification body for both platforms
    const notificationTitle = isCallNotification && data.caller_name 
      ? `${data.caller_name} is calling you`
      : title;
    const notificationBody = isCallNotification && data.caller_name 
      ? `${data.caller_name} is calling you`
      : body;

    // Handle clear notification - send data-only message
    if (isClearNotification) {
      console.log('📱 PUSH: Sending clear notification (data-only)');
      const clearMessage = {
        message: {
          token: profile.fcm_token,
          data: stringifiedData,
          android: {
            priority: 'HIGH',
            data: stringifiedData,
          },
          apns: {
            payload: {
              aps: {
                'content-available': 1,
                'mutable-content': 0,
              },
              ...stringifiedData,
            }
          }
        }
      };
      
      console.log('📱 PUSH: Clear notification message:', JSON.stringify(clearMessage, null, 2));
      
      const response = await fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(clearMessage),
      });

      if (!response.ok) {
        const errorText = await response.text()
        console.error('❌ PUSH: Clear notification FCM Error:', errorText)
        return new Response(
          JSON.stringify({ error: 'Failed to send clear notification', details: errorText }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }

      const result = await response.json()
      console.log('✅ PUSH: Clear notification sent successfully:', result)

      return new Response(
        JSON.stringify({ 
          success: true, 
          messageId: result.name,
          message: 'Clear notification sent successfully' 
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Build message depending on type.
    // For incoming_call on iOS we now send an ALERT-style APNs payload with
    // category CALL_CATEGORY so the system shows Accept/Decline actions.
    // Android keeps using data portion and high priority.
    const message = type === 'incoming_call'
      ? {
          message: {
            token: profile.fcm_token,
            data: stringifiedData,
            android: {
              priority: 'HIGH'
            },
            apns: {
              headers: {
                // Visible alert for call invite
                'apns-push-type': 'alert',
                'apns-priority': '10',
                ...(data.call_id ? { 'apns-collapse-id': String(data.call_id) } : {}),
              },
              payload: {
                aps: {
                  alert: {
                    title: `${data.caller_name || 'Someone'} is calling`,
                    body: `Incoming ${data.call_type || 'audio'} call`
                  },
                  sound: 'call_ringtone.wav',
                  badge: 1,
                  category: 'CALL_CATEGORY',
                  // iOS 15+: allow to break through Focus for calls
                  'interruption-level': 'time-sensitive',
                  'mutable-content': 0
                },
                call_id: data.call_id || '',
                caller_id: data.caller_id || '',
                caller_name: data.caller_name || '',
                call_type: data.call_type || 'audio',
                match_id: data.match_id || '',
                type: 'incoming_call',
                action: 'incoming_call'
              }
            }
          }
        }
      : {
          message: {
            token: profile.fcm_token,
            notification: {
              title: notificationTitle,
              body: notificationBody,
            },
            data: stringifiedData,
            android: {
              priority: 'HIGH',
              notification: {
                icon: isCallNotification ? 'ic_call' : 'ic_notification',
                color: isCallNotification ? '#4CAF50' : '#FF6B6B',
                sound: isCallNotification ? 'call_ringtone' : 'default',
                notification_priority: isCallNotification ? 'PRIORITY_MAX' : 'PRIORITY_DEFAULT',
                visibility: 'public',
                channel_id: isCallNotification ? 'call_notifications' : 'default_notifications',
                title: notificationTitle,
                body: notificationBody,
                ...(isCallNotification && data.caller_image_url && { image: data.caller_image_url }),
              },
            },
            apns: {
              headers: {
                // Alert push for visible notifications
                'apns-push-type': 'alert',
                'apns-priority': '10',
              },
              payload: {
                aps: {
                  sound: isCallNotification ? 'call_ringtone.wav' : 'default',
                  badge: 1,
                  category: isCallNotification ? 'CALL_CATEGORY' : undefined,
                  'mutable-content': isCallNotification ? 1 : 0,
                  alert: {
                    title: notificationTitle,
                    body: notificationBody,
                    'launch-image': isCallNotification ? 'call_background.png' : undefined
                  }
                },
                ...(isCallNotification && data.caller_image_url && { caller_image_url: data.caller_image_url }),
                ...(isCallNotification && {
                  call_id: data.call_id || '',
                  caller_id: data.caller_id || '',
                  caller_name: data.caller_name || '',
                  call_type: data.call_type || 'audio',
                  match_id: data.match_id || '',
                  action: 'incoming_call'
                })
              }
            }
          }
        }
    // Targeted debug: confirm APNs headers and aps.category for iOS
    try {
      const apns = (message as any)?.message?.apns;
      const aps = apns?.payload?.aps;
      console.log('🔎 APNs headers:', apns?.headers);
      console.log('🔎 APNs aps.category:', aps?.category);
      console.log('🔎 APNs alert:', aps?.alert);
    } catch (_) {}

    console.log('📱 PUSH: FCM message structure:', JSON.stringify(message, null, 2));
    
    console.log('📱 PUSH: Sending FCM request to:', fcmUrl);
    const response = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    })

    console.log('📱 PUSH: FCM response status:', response.status);
    console.log('📱 PUSH: FCM response headers:', Object.fromEntries(response.headers.entries()));

    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ PUSH: FCM Error:', errorText)
      return new Response(
        JSON.stringify({ error: 'Failed to send notification', details: errorText }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const result = await response.json()
    console.log('✅ PUSH: Notification sent successfully:', result)

    return new Response(
      JSON.stringify({ 
        success: true, 
        messageId: result.name,
        message: 'Notification sent successfully' 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error sending notification:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

// Generate Firebase access token using JWT
async function getFirebaseAccessToken(privateKey: string, clientEmail: string, projectId: string): Promise<string> {
  try {
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600
    }

    // Create JWT token using Web Crypto API
    const jwt = await createJWT(payload, privateKey)
    
    // Exchange JWT for access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
    })
    
    const tokenData = await tokenResponse.json()
    return tokenData.access_token
  } catch (error) {
    console.error('Error generating access token:', error)
    throw error
  }
}

// Create JWT using Web Crypto API
async function createJWT(payload: any, privateKey: string): Promise<string> {
  const header = {
    alg: "RS256",
    typ: "JWT"
  }

  // Encode header and payload
  const encodedHeader = base64UrlEncode(JSON.stringify(header))
  const encodedPayload = base64UrlEncode(JSON.stringify(payload))
  
  // Create signature
  const data = `${encodedHeader}.${encodedPayload}`
  const signature = await signData(data, privateKey)
  
  return `${data}.${signature}`
}

// Base64 URL encoding
function base64UrlEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

// Sign data using Web Crypto API
async function signData(data: string, privateKeyPem: string): Promise<string> {
  try {
    // Convert PEM to ArrayBuffer
    const pemHeader = "-----BEGIN PRIVATE KEY-----"
    const pemFooter = "-----END PRIVATE KEY-----"
    const pemContents = privateKeyPem
      .replace(pemHeader, '')
      .replace(pemFooter, '')
      .replace(/\s/g, '')
    
    const binaryDer = atob(pemContents)
    const keyData = new Uint8Array(binaryDer.length)
    for (let i = 0; i < binaryDer.length; i++) {
      keyData[i] = binaryDer.charCodeAt(i)
    }
    
    // Import the private key
    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      keyData,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    )
    
    // Sign the data
    const dataBuffer = new TextEncoder().encode(data)
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      cryptoKey,
      dataBuffer
    )
    
    // Convert signature to base64url
    const signatureArray = new Uint8Array(signature)
    let binary = ''
    for (let i = 0; i < signatureArray.length; i++) {
      binary += String.fromCharCode(signatureArray[i])
    }
    
    return base64UrlEncode(binary)
  } catch (error) {
    console.error('Error signing data:', error)
    throw error
  }
}