-- Fix location columns in profiles table
-- This adds the missing latitude and longitude columns that the location service expects

-- 1. Add latitude and longitude columns to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 2. Add simple index for location-based queries (without PostGIS)
CREATE INDEX IF NOT EXISTS idx_profiles_location 
ON profiles (latitude, longitude) 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 3. Verify the columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name IN ('latitude', 'longitude', 'location')
ORDER BY column_name;

-- 4. Test the location update (this should work now)
-- UPDATE profiles 
-- SET latitude = 12.9043259, longitude = 77.5956799, location = 'Bangalore, India'
-- WHERE id = '195cb857-3a05-4425-a6ba-3dd836ca8627';
