-- Create the disappearing_photos table
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS public.disappearing_photos (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id uuid REFERENCES public.matches(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    photo_url text NOT NULL,
    view_duration integer NOT NULL, -- in seconds
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    viewed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    viewed_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL
);

-- Enable RLS
ALTER TABLE public.disappearing_photos ENABLE ROW LEVEL SECURITY;

-- Create policies for disappearing_photos table
CREATE POLICY "Allow sender to insert disappearing photos"
ON public.disappearing_photos
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Allow match participants to view disappearing photos"
ON public.disappearing_photos
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.matches
        WHERE (matches.id = disappearing_photos.match_id)
          AND (
                (matches.user_id_1 = auth.uid())
             OR (matches.user_id_2 = auth.uid())
          )
    )
    AND (disappearing_photos.expires_at > now())
);

CREATE POLICY "Allow sender to delete own disappearing photos"
ON public.disappearing_photos
FOR DELETE
TO authenticated
USING (auth.uid() = sender_id);

CREATE POLICY "Allow marking photo as viewed by recipient"
ON public.disappearing_photos
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.matches
        WHERE (matches.id = disappearing_photos.match_id)
          AND (
                (matches.user_id_1 = auth.uid())
             OR (matches.user_id_2 = auth.uid())
          )
    )
    AND (disappearing_photos.viewed_by IS NULL)
    AND (auth.uid() <> sender_id)
)
WITH CHECK (
    (auth.uid() = viewed_by)
);
