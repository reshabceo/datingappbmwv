-- Create audio_messages table
CREATE TABLE IF NOT EXISTS public.audio_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    audio_url TEXT NOT NULL,
    duration INTEGER NOT NULL DEFAULT 0, -- Duration in seconds
    file_size INTEGER NOT NULL DEFAULT 0, -- File size in bytes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_audio_messages_match_id ON public.audio_messages(match_id);
CREATE INDEX IF NOT EXISTS idx_audio_messages_sender_id ON public.audio_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_audio_messages_created_at ON public.audio_messages(created_at);

-- Enable RLS (Row Level Security)
ALTER TABLE public.audio_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for audio_messages

-- Policy: Users can view audio messages from matches they're part of
CREATE POLICY "Users can view audio messages from their matches" ON public.audio_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.matches m
            WHERE m.id = audio_messages.match_id
            AND (m.user_id_1 = auth.uid() OR m.user_id_2 = auth.uid())
        )
    );

-- Policy: Users can insert audio messages to matches they're part of
CREATE POLICY "Users can insert audio messages to their matches" ON public.audio_messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.matches m
            WHERE m.id = audio_messages.match_id
            AND (m.user_id_1 = auth.uid() OR m.user_id_2 = auth.uid())
        )
    );

-- Policy: Users can update their own audio messages (for read status)
CREATE POLICY "Users can update their own audio messages" ON public.audio_messages
    FOR UPDATE USING (
        sender_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.matches m
            WHERE m.id = audio_messages.match_id
            AND (m.user_id_1 = auth.uid() OR m.user_id_2 = auth.uid())
        )
    );

-- Policy: Users can delete their own audio messages
CREATE POLICY "Users can delete their own audio messages" ON public.audio_messages
    FOR DELETE USING (sender_id = auth.uid());

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_audio_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_audio_messages_updated_at
    BEFORE UPDATE ON public.audio_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_audio_messages_updated_at();

-- Function to get audio messages for a match
CREATE OR REPLACE FUNCTION get_audio_messages(p_match_id UUID)
RETURNS TABLE (
    id UUID,
    match_id UUID,
    sender_id UUID,
    audio_url TEXT,
    duration INTEGER,
    file_size INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    is_read BOOLEAN,
    sender_name TEXT,
    sender_image TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        am.id,
        am.match_id,
        am.sender_id,
        am.audio_url,
        am.duration,
        am.file_size,
        am.created_at,
        am.is_read,
        p.name as sender_name,
        COALESCE(
            (SELECT jsonb_array_elements_text(p.image_urls) LIMIT 1),
            (SELECT jsonb_array_elements_text(p.photos) LIMIT 1)
        ) as sender_image
    FROM public.audio_messages am
    JOIN public.profiles p ON p.id = am.sender_id
    WHERE am.match_id = p_match_id
    ORDER BY am.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_audio_messages(UUID) TO authenticated;

-- Function to mark audio messages as read
CREATE OR REPLACE FUNCTION mark_audio_messages_as_read(p_match_id UUID, p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE public.audio_messages 
    SET is_read = TRUE, updated_at = NOW()
    WHERE match_id = p_match_id 
    AND sender_id != p_user_id 
    AND is_read = FALSE;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION mark_audio_messages_as_read(UUID, UUID) TO authenticated;
