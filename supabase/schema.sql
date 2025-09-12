-- Profiles table
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  age int not null,
  image_urls jsonb default '[]'::jsonb,
  location text,
  distance text,
  description text,
  hobbies jsonb default '[]'::jsonb,
  is_active boolean default false,
  created_at timestamp with time zone default now()
);

-- Chats
create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references public.profiles(id) on delete cascade,
  user_b_id uuid not null references public.profiles(id) on delete cascade,
  last_message_at timestamptz
);

-- Messages
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  text text not null,
  created_at timestamptz default now()
);

-- Matches
create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  other_user_id uuid not null references public.profiles(id) on delete cascade,
  matched_at timestamptz default now()
);

-- Stories
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_url text not null,
  posted_at timestamptz default now(),
  expires_at timestamptz
);

-- RLS
alter table public.profiles enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.matches enable row level security;
alter table public.stories enable row level security;

-- Profiles: anyone can read active profiles
create policy profiles_read_active on public.profiles
  for select using (is_active = true);

-- Chats: members only
create policy chats_member_read on public.chats
  for select using (
    exists (
      select 1 from public.profiles p
      where (p.id = user_a_id or p.id = user_b_id)
    )
  );

-- Messages: chat members only
create policy messages_member_read on public.messages
  for select using (
    exists (
      select 1 from public.chats c where c.id = chat_id
    )
  );

-- Stories: public read for now (can tighten later)
create policy stories_read on public.stories for select using (true);


