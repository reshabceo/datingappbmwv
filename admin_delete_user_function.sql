-- Create admin function to safely delete users
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION admin_delete_user(user_email TEXT)
RETURNS TEXT AS $$
DECLARE
  user_id UUID;
  deleted_count INTEGER;
BEGIN
  -- Get user ID
  SELECT id INTO user_id FROM auth.users WHERE email = user_email;
  
  IF user_id IS NULL THEN
    RETURN 'User not found: ' || user_email;
  END IF;
  
  -- Delete from profiles first (due to foreign key constraints)
  DELETE FROM public.profiles WHERE id = user_id;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  -- Delete from auth.users
  DELETE FROM auth.users WHERE id = user_id;
  
  RETURN 'User deleted successfully: ' || user_email || ' (Profile records deleted: ' || deleted_count || ')';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users (or specific admin role)
GRANT EXECUTE ON FUNCTION admin_delete_user(TEXT) TO authenticated;

-- Usage example:
-- SELECT admin_delete_user('ceo@boostmysites.com');
