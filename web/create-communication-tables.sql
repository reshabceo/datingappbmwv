-- Create conversation_metadata table
CREATE TABLE IF NOT EXISTS conversation_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    message_count INTEGER DEFAULT 0,
    is_flagged BOOLEAN DEFAULT FALSE,
    flagged_reason TEXT,
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create message_analytics table
CREATE TABLE IF NOT EXISTS message_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    total_messages INTEGER DEFAULT 0,
    flagged_messages INTEGER DEFAULT 0,
    active_conversations INTEGER DEFAULT 0,
    new_conversations INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(date)
);

-- Update messages table to add missing columns if they don't exist
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_flagged BOOLEAN DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS flagged_reason TEXT;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_conversation_metadata_match_id ON conversation_metadata(match_id);
CREATE INDEX IF NOT EXISTS idx_conversation_metadata_last_activity ON conversation_metadata(last_activity);
CREATE INDEX IF NOT EXISTS idx_conversation_metadata_is_flagged ON conversation_metadata(is_flagged);
CREATE INDEX IF NOT EXISTS idx_message_analytics_date ON message_analytics(date);
CREATE INDEX IF NOT EXISTS idx_messages_match_id ON messages(match_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_is_flagged ON messages(is_flagged);

-- Enable RLS on new tables
ALTER TABLE conversation_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_analytics ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for conversation_metadata
CREATE POLICY "Allow authenticated users to view conversation metadata" 
ON conversation_metadata FOR SELECT 
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow authenticated users to insert conversation metadata" 
ON conversation_metadata FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Allow authenticated users to update conversation metadata" 
ON conversation_metadata FOR UPDATE 
USING (auth.uid() IS NOT NULL);

-- Create RLS policies for message_analytics
CREATE POLICY "Allow authenticated users to view message analytics" 
ON message_analytics FOR SELECT 
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow authenticated users to insert message analytics" 
ON message_analytics FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Allow authenticated users to update message analytics" 
ON message_analytics FOR UPDATE 
USING (auth.uid() IS NOT NULL);

-- Create RLS policies for messages (if not already exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'messages' 
        AND policyname = 'Allow authenticated users to view messages'
    ) THEN
        CREATE POLICY "Allow authenticated users to view messages" 
        ON messages FOR SELECT 
        USING (auth.uid() IS NOT NULL);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'messages' 
        AND policyname = 'Allow authenticated users to insert messages'
    ) THEN
        CREATE POLICY "Allow authenticated users to insert messages" 
        ON messages FOR INSERT 
        WITH CHECK (auth.uid() IS NOT NULL);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'messages' 
        AND policyname = 'Allow authenticated users to update messages'
    ) THEN
        CREATE POLICY "Allow authenticated users to update messages" 
        ON messages FOR UPDATE 
        USING (auth.uid() IS NOT NULL);
    END IF;
END $$;

-- Create function to update conversation metadata when messages are added
CREATE OR REPLACE FUNCTION update_conversation_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert conversation metadata
    INSERT INTO conversation_metadata (match_id, last_activity, message_count)
    VALUES (NEW.match_id, NEW.created_at, 1)
    ON CONFLICT (match_id) 
    DO UPDATE SET
        last_activity = NEW.created_at,
        message_count = conversation_metadata.message_count + 1,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update conversation metadata
DROP TRIGGER IF EXISTS trigger_update_conversation_metadata ON messages;
CREATE TRIGGER trigger_update_conversation_metadata
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_metadata();

-- Create function to update daily message analytics
CREATE OR REPLACE FUNCTION update_daily_message_analytics()
RETURNS TRIGGER AS $$
DECLARE
    message_date DATE := DATE(NEW.created_at);
    flagged_count INTEGER := 0;
    total_count INTEGER := 0;
BEGIN
    -- Count total and flagged messages for the date
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE is_flagged = TRUE)
    INTO total_count, flagged_count
    FROM messages 
    WHERE DATE(created_at) = message_date;
    
    -- Update or insert daily analytics
    INSERT INTO message_analytics (date, total_messages, flagged_messages)
    VALUES (message_date, total_count, flagged_count)
    ON CONFLICT (date) 
    DO UPDATE SET
        total_messages = EXCLUDED.total_messages,
        flagged_messages = EXCLUDED.flagged_messages,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update daily analytics
DROP TRIGGER IF EXISTS trigger_update_daily_analytics ON messages;
CREATE TRIGGER trigger_update_daily_analytics
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_message_analytics();