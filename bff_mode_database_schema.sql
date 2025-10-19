-- BFF Mode Database Schema
-- This script adds support for BFF (Best Friends Forever) mode to the existing dating app

-- Step 1: Add BFF-specific fields to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS mode_preference TEXT DEFAULT 'dating' CHECK (mode_preference IN ('dating', 'bff', 'both')),
ADD COLUMN IF NOT EXISTS friendship_interests TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS activity_level TEXT DEFAULT 'moderate' CHECK (activity_level IN ('active', 'moderate', 'casual')),
ADD COLUMN IF NOT EXISTS availability TEXT DEFAULT 'weekends' CHECK (availability IN ('weekdays', 'weekends', 'evenings', 'flexible'));

-- Step 2: Create BFF-specific swipes table (separate from dating swipes)
CREATE TABLE IF NOT EXISTS public.bff_swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  swiped_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('like', 'pass')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(swiper_id, swiped_id)
);

-- Step 3: Create BFF matches table (separate from dating matches)
CREATE TABLE IF NOT EXISTS public.bff_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id_1 UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_id_2 UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'matched' CHECK (status IN ('matched', 'unmatched', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id_1, user_id_2)
);

-- Step 4: Create BFF chats table (separate from dating chats)
CREATE TABLE IF NOT EXISTS public.bff_chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 5: Create BFF messages table (separate from dating messages)
CREATE TABLE IF NOT EXISTS public.bff_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.bff_chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 6: Enable RLS on new tables
ALTER TABLE public.bff_swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bff_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bff_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bff_messages ENABLE ROW LEVEL SECURITY;

-- Step 7: Create RLS policies for BFF swipes
CREATE POLICY "Users can view their own BFF swipes"
ON public.bff_swipes FOR SELECT
USING (swiper_id = auth.uid() OR swiped_id = auth.uid());

CREATE POLICY "Users can create BFF swipes"
ON public.bff_swipes FOR INSERT
WITH CHECK (swiper_id = auth.uid());

-- Step 8: Create RLS policies for BFF matches
CREATE POLICY "Users can view their own BFF matches"
ON public.bff_matches FOR SELECT
USING (user_id_1 = auth.uid() OR user_id_2 = auth.uid());

CREATE POLICY "Users can create BFF matches"
ON public.bff_matches FOR INSERT
WITH CHECK (user_id_1 = auth.uid() OR user_id_2 = auth.uid());

-- Step 9: Create RLS policies for BFF chats
CREATE POLICY "Users can view their own BFF chats"
ON public.bff_chats FOR SELECT
USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

CREATE POLICY "Users can create BFF chats"
ON public.bff_chats FOR INSERT
WITH CHECK (user_a_id = auth.uid() OR user_b_id = auth.uid());

-- Step 10: Create RLS policies for BFF messages
CREATE POLICY "Users can view messages in their BFF chats"
ON public.bff_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.bff_chats 
    WHERE bff_chats.id = bff_messages.chat_id 
    AND (bff_chats.user_a_id = auth.uid() OR bff_chats.user_b_id = auth.uid())
  )
);

CREATE POLICY "Users can send messages in their BFF chats"
ON public.bff_messages FOR INSERT
WITH CHECK (
  sender_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM public.bff_chats 
    WHERE bff_chats.id = bff_messages.chat_id 
    AND (bff_chats.user_a_id = auth.uid() OR bff_chats.user_b_id = auth.uid())
  )
);

-- Step 11: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bff_swipes_swiper_id ON public.bff_swipes(swiper_id);
CREATE INDEX IF NOT EXISTS idx_bff_swipes_swiped_id ON public.bff_swipes(swiped_id);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_1 ON public.bff_matches(user_id_1);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_2 ON public.bff_matches(user_id_2);
CREATE INDEX IF NOT EXISTS idx_bff_chats_user_a_id ON public.bff_chats(user_a_id);
CREATE INDEX IF NOT EXISTS idx_bff_chats_user_b_id ON public.bff_chats(user_b_id);
CREATE INDEX IF NOT EXISTS idx_bff_messages_chat_id ON public.bff_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_bff_messages_sender_id ON public.bff_messages(sender_id);

-- Step 12: Create function to handle BFF matching logic
CREATE OR REPLACE FUNCTION handle_bff_match()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if both users liked each other
  IF EXISTS (
    SELECT 1 FROM public.bff_swipes 
    WHERE swiper_id = NEW.swiped_id 
    AND swiped_id = NEW.swiper_id 
    AND action = 'like'
  ) AND NEW.action = 'like' THEN
    -- Create a match
    INSERT INTO public.bff_matches (user_id_1, user_id_2)
    VALUES (NEW.swiper_id, NEW.swiped_id)
    ON CONFLICT (user_id_1, user_id_2) DO NOTHING;
    
    -- Create a chat
    INSERT INTO public.bff_chats (user_a_id, user_b_id)
    VALUES (NEW.swiper_id, NEW.swiped_id)
    ON CONFLICT (user_a_id, user_b_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 13: Create trigger for BFF matching
CREATE TRIGGER trigger_bff_match
  AFTER INSERT ON public.bff_swipes
  FOR EACH ROW
  EXECUTE FUNCTION handle_bff_match();

-- Step 14: Update existing profiles to have default BFF settings
UPDATE public.profiles 
SET 
  mode_preference = 'both',
  friendship_interests = ARRAY['Music', 'Sports', 'Travel', 'Movies', 'Food'],
  activity_level = 'moderate',
  availability = 'weekends'
WHERE mode_preference IS NULL;

-- Step 15: Create view for BFF profile discovery
CREATE OR REPLACE VIEW bff_discovery_profiles AS
SELECT 
  p.id,
  p.name,
  p.age,
  p.location,
  p.photos,
  p.friendship_interests,
  p.activity_level,
  p.availability,
  p.created_at
FROM public.profiles p
WHERE p.is_active = true
AND p.mode_preference IN ('bff', 'both')
AND p.id != auth.uid();

-- Grant access to the view
GRANT SELECT ON public.bff_discovery_profiles TO authenticated;
