-- Add cleared_by_user column to messages and disappearing_photos tables
-- Run this in Supabase SQL Editor

-- Add cleared_by_user column to messages table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' 
        AND column_name = 'cleared_by_user'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.messages 
        ADD COLUMN cleared_by_user UUID REFERENCES auth.users(id);
    END IF;
END $$;

-- Add cleared_by_user column to disappearing_photos table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'disappearing_photos' 
        AND column_name = 'cleared_by_user'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.disappearing_photos 
        ADD COLUMN cleared_by_user UUID REFERENCES auth.users(id);
    END IF;
END $$;

-- Verify the columns were added
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name IN ('messages', 'disappearing_photos') 
AND column_name = 'cleared_by_user'
AND table_schema = 'public'
ORDER BY table_name;
