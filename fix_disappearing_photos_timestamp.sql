-- Fix disappearing_photos table to ensure created_at field exists
-- Run this in Supabase SQL Editor

-- Add created_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'disappearing_photos' 
        AND column_name = 'created_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.disappearing_photos 
        ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- Update existing records to have proper timestamps
UPDATE public.disappearing_photos 
SET created_at = NOW() 
WHERE created_at IS NULL;

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'disappearing_photos' 
AND table_schema = 'public'
ORDER BY ordinal_position;
