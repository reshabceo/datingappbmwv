-- Create function to send missed call notification when call is canceled or times out
CREATE OR REPLACE FUNCTION handle_call_state_change()
RETURNS TRIGGER AS $$
DECLARE
    caller_profile RECORD;
    receiver_profile RECORD;
    call_duration INTERVAL;
BEGIN
    -- Only process if state changed to a terminal state
    IF OLD.state != NEW.state AND NEW.state IN ('canceled', 'timeout', 'declined') THEN
        
        -- Get caller profile for missed call notification
        SELECT name, fcm_token INTO caller_profile
        FROM profiles 
        WHERE id = NEW.caller_id;
        
        -- Get receiver profile for FCM token
        SELECT fcm_token INTO receiver_profile
        FROM profiles 
        WHERE id = NEW.receiver_id;
        
        -- Only send missed call notification if receiver has FCM token
        IF receiver_profile.fcm_token IS NOT NULL AND caller_profile.name IS NOT NULL THEN
            
            -- Calculate call duration if call was started
            IF NEW.started_at IS NOT NULL THEN
                call_duration := NOW() - NEW.started_at;
            ELSE
                call_duration := INTERVAL '0 seconds';
            END IF;
            
            -- Send missed call notification via edge function
            PERFORM net.http_post(
                url := 'https://lovebug-dating-app.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
                ),
                body := jsonb_build_object(
                    'userId', NEW.receiver_id,
                    'type', 'missed_call',
                    'title', '📞 Missed Call',
                    'body', 'You missed a call from ' || caller_profile.name,
                    'data', jsonb_build_object(
                        'call_id', NEW.id,
                        'caller_name', caller_profile.name,
                        'call_type', NEW.call_type,
                        'call_duration', EXTRACT(EPOCH FROM call_duration)::text,
                        'action', 'missed_call'
                    )
                )
            );
            
            RAISE LOG 'Missed call notification sent to user % for call %', NEW.receiver_id, NEW.id;
        END IF;
        
        -- Also send call_ended notification to clear any active notifications
        IF receiver_profile.fcm_token IS NOT NULL THEN
            PERFORM net.http_post(
                url := 'https://lovebug-dating-app.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
                ),
                body := jsonb_build_object(
                    'userId', NEW.receiver_id,
                    'type', 'call_ended',
                    'title', 'Call Ended',
                    'body', 'Call has ended',
                    'data', jsonb_build_object(
                        'call_id', NEW.id,
                        'caller_name', caller_profile.name,
                        'call_type', NEW.call_type,
                        'action', 'call_ended'
                    )
                )
            );
            
            RAISE LOG 'Call ended notification sent to user % for call %', NEW.receiver_id, NEW.id;
        END IF;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on call_sessions table
DROP TRIGGER IF EXISTS call_state_change_trigger ON call_sessions;
CREATE TRIGGER call_state_change_trigger
    AFTER UPDATE ON call_sessions
    FOR EACH ROW
    EXECUTE FUNCTION handle_call_state_change();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres;
GRANT EXECUTE ON FUNCTION handle_call_state_change() TO postgres;
