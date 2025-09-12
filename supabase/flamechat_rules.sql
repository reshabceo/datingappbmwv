





-- FlameChats server-side suggestions (manual apply in Supabase SQL editor)
-- 1) Add extended flag table (simple version)
create table if not exists public.chat_extensions (
  match_id uuid primary key references public.matches(id) on delete cascade,
  extended_at timestamptz default now()
);

-- 2) Enforce 5-minute rule on insert into messages (allow if within 5 min or extended exists)
create or replace function public.enforce_flame_window()
returns trigger as $$
declare
  m_row public.matches;
  ok boolean := false;
begin
  select * into m_row from public.matches where id = new.match_id;
  if m_row is null then
    raise exception 'Match not found';
  end if;
  if now() <= m_row.created_at + interval '5 minutes' then
    ok := true;
  end if;
  if exists(select 1 from public.chat_extensions where match_id = new.match_id) then
    ok := true;
  end if;
  if not ok then






    raise exception 'FlameChat expired';
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_enforce_flame_window on public.messages;
create trigger trg_enforce_flame_window
before insert on public.messages
for each row execute function public.enforce_flame_window();

-- 3) Match upgrade trigger: when both users liked (swipes), insert matched once
-- Optional: if using swipes table per database_schema.sql
create or replace function public.upgrade_match_on_reciprocal()
returns trigger as $$
begin
  if new.action in ('like','super_like') then
    if exists(select 1 from public.swipes s where s.swiper_id = new.swiped_id and s.swiped_id = new.swiper_id and s.action in ('like','super_like')) then
      -- ensure a single row for the pair
      insert into public.matches (user_id_1, user_id_2, status)
      select least(new.swiper_id, new.swiped_id), greatest(new.swiper_id, new.swiper_id), 'matched'
      on conflict do nothing;
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_upgrade_match_on_reciprocal on public.swipes;
create trigger trg_upgrade_match_on_reciprocal
after insert on public.swipes
for each row execute function public.upgrade_match_on_reciprocal();
