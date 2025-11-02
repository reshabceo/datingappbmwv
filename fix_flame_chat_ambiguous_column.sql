-- Fix Flame Chat Ambiguous Column Error
-- This fixes the "column reference flame_started_at is ambiguous" error

-- Fix the start_flame_chat function
CREATE OR REPLACE FUNCTION start_flame_chat(
  p_match_id uuid,
  p_user_id uuid
) RETURNS TABLE(
  mode text,
  flame_started_at timestamptz,
  flame_expires_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_mode text;
  v_started timestamptz;
  v_expires timestamptz;
BEGIN
  -- Dating match
  SELECT 'dating', m.flame_started_at, m.flame_expires_at
    INTO v_mode, v_started, v_expires
  FROM matches m
  WHERE id = p_match_id
    AND (user_id_1 = p_user_id OR user_id_2 = p_user_id)
  LIMIT 1;

  IF FOUND THEN
    IF v_started IS NULL THEN
      UPDATE matches
         SET flame_started_at = NOW(),
             flame_expires_at = NOW() + INTERVAL '5 minutes'
       WHERE id = p_match_id
       RETURNING matches.flame_started_at, matches.flame_expires_at INTO v_started, v_expires;
    END IF;
    RETURN QUERY SELECT v_mode, v_started, v_expires;
    RETURN;
  END IF;

  -- BFF match
  SELECT 'bff', bm.flame_started_at, bm.flame_expires_at
    INTO v_mode, v_started, v_expires
  FROM bff_matches bm
  WHERE id = p_match_id
    AND (user_id_1 = p_user_id OR user_id_2 = p_user_id)
  LIMIT 1;

  IF FOUND THEN
    IF v_started IS NULL THEN
      UPDATE bff_matches
         SET flame_started_at = NOW(),
             flame_expires_at = NOW() + INTERVAL '5 minutes'
       WHERE id = p_match_id
       RETURNING bff_matches.flame_started_at, bff_matches.flame_expires_at INTO v_started, v_expires;
    END IF;
    RETURN QUERY SELECT v_mode, v_started, v_expires;
    RETURN;
  END IF;

  RAISE EXCEPTION 'Match not found or user not authorized';
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION start_flame_chat(uuid, uuid) TO anon, authenticated;

-- Test message
DO $$
BEGIN
  RAISE NOTICE '✅ Flame chat function fixed! Ambiguous column references resolved.';
END $$;

