-- Fix signup database error by creating automatic profile creation
-- Run this in Supabase SQL Editor

-- Create function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Create profile for new user
  INSERT INTO public.profiles (id, email, name, age, is_active, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'name',
      NEW.raw_user_meta_data->>'full_name', 
      NEW.user_metadata->>'name',
      split_part(NEW.email, '@', 1),
      'User'
    ),
    18, -- Default age
    false, -- Profile not active until completed
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING; -- Don't overwrite existing profiles
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't break signup
  RAISE LOG 'Error creating profile for user %: % (SQLSTATE: %)', NEW.email, SQLERRM, SQLSTATE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to run after user is inserted
DROP TRIGGER IF EXISTS trigger_create_profile_on_signup ON auth.users;
CREATE TRIGGER trigger_create_profile_on_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_signup();

-- Also create a policy to allow the trigger to insert profiles
DROP POLICY IF EXISTS "Allow automatic profile creation" ON profiles;
CREATE POLICY "Allow automatic profile creation" ON profiles
  FOR INSERT WITH CHECK (true);

-- Test the fix by checking if we can create a test user
-- (Don't actually run this, just for reference)
-- SELECT handle_new_user_signup() FROM auth.users LIMIT 1;
