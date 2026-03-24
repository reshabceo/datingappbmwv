-- RPCs for ImprovedIceBreakerWidget
-- Run this in your Supabase SQL Editor

DROP FUNCTION IF EXISTS public.get_match_icebreakers(UUID, UUID);
DROP FUNCTION IF EXISTS public.get_icebreaker_usage_status(UUID);
DROP FUNCTION IF EXISTS public.mark_icebreaker_used(UUID, TEXT, UUID);

-- 1. Function to get match icebreakers status
CREATE OR REPLACE FUNCTION public.get_match_icebreakers(p_match_id UUID, p_user_id UUID)
RETURNS TABLE (
  should_show BOOLEAN,
  out_ice_breakers JSONB
) AS $$
DECLARE
  v_used BOOLEAN;
  v_ice_breakers JSONB;
BEGIN
  -- Check if any ice breaker has been used for this match
  SELECT EXISTS(SELECT 1 FROM public.ice_breaker_usage WHERE match_id = p_match_id) INTO v_used;
  
  -- Get ice breakers from match_enhancements
  SELECT me.ice_breakers INTO v_ice_breakers 
  FROM public.match_enhancements me 
  WHERE me.match_id = p_match_id;
  
  RETURN QUERY SELECT NOT v_used, v_ice_breakers;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to get icebreaker usage status
CREATE OR REPLACE FUNCTION public.get_icebreaker_usage_status(p_match_id UUID)
RETURNS TABLE (
  has_been_used BOOLEAN,
  out_used_by_user_id UUID,
  out_used_ice_breaker_text TEXT,
  out_used_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    TRUE,
    ibu.used_by_user_id,
    ibu.ice_breaker_text,
    ibu.used_at
  FROM public.ice_breaker_usage ibu
  WHERE ibu.match_id = p_match_id
  ORDER BY ibu.used_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Function to mark icebreaker as used
CREATE OR REPLACE FUNCTION public.mark_icebreaker_used(
  p_match_id UUID,
  p_ice_breaker_text TEXT,
  p_user_id UUID
) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.ice_breaker_usage (match_id, ice_breaker_text, used_by_user_id)
  VALUES (p_match_id, p_ice_breaker_text, p_user_id)
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_match_icebreakers(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_icebreaker_usage_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_icebreaker_used(UUID, TEXT, UUID) TO authenticated;
