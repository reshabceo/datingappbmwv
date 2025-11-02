-- Flame Chat Support

-- Extend matches table
alter table matches
    add column if not exists flame_started_at timestamptz,
    add column if not exists flame_expires_at timestamptz;

-- Extend BFF matches table
alter table bff_matches
    add column if not exists flame_started_at timestamptz,
    add column if not exists flame_expires_at timestamptz;

-- RPC: start flame chat (works for dating & BFF)
create or replace function start_flame_chat(
  p_match_id uuid,
  p_user_id uuid
) returns table(
  mode text,
  flame_started_at timestamptz,
  flame_expires_at timestamptz
)
language plpgsql
security definer
as $$
declare
  v_mode text;
  v_started timestamptz;
  v_expires timestamptz;
begin
  -- Dating match
  select 'dating', m.flame_started_at, m.flame_expires_at
    into v_mode, v_started, v_expires
  from matches m
  where id = p_match_id
    and (user_id_1 = p_user_id or user_id_2 = p_user_id)
  limit 1;

  if found then
    if v_started is null then
      update matches
         set flame_started_at = now(),
             flame_expires_at = now() + interval '5 minutes'
       where id = p_match_id
       returning matches.flame_started_at, matches.flame_expires_at into v_started, v_expires;
    end if;
    return query select v_mode, v_started, v_expires;
  end if;

  -- BFF match
  select 'bff', bm.flame_started_at, bm.flame_expires_at
    into v_mode, v_started, v_expires
  from bff_matches bm
  where id = p_match_id
    and (user_id_1 = p_user_id or user_id_2 = p_user_id)
  limit 1;

  if found then
    if v_started is null then
      update bff_matches
         set flame_started_at = now(),
             flame_expires_at = now() + interval '5 minutes'
       where id = p_match_id
       returning bff_matches.flame_started_at, bff_matches.flame_expires_at into v_started, v_expires;
    end if;
    return query select v_mode, v_started, v_expires;
  end if;

  raise exception 'Match not found or user not authorized';
end;
$$;

-- RPC: fetch current flame status
create or replace function get_flame_status(
  p_match_id uuid,
  p_user_id uuid
) returns table(
  mode text,
  flame_started_at timestamptz,
  flame_expires_at timestamptz
)
language plpgsql
security definer
as $$
begin
  return query
  select 'dating', m.flame_started_at, m.flame_expires_at
    from matches m
   where id = p_match_id
     and (user_id_1 = p_user_id or user_id_2 = p_user_id)
  union all
  select 'bff', bm.flame_started_at, bm.flame_expires_at
    from bff_matches bm
   where id = p_match_id
     and (user_id_1 = p_user_id or user_id_2 = p_user_id);
end;
$$;

