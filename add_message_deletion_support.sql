-- Message deletion support (per-user and global)

-- Text messages
alter table messages
    add column if not exists deleted_by uuid[] default '{}'::uuid[];

alter table messages
    add column if not exists deleted_for_everyone boolean default false;

alter table messages
    add column if not exists deleted_at timestamptz;

update messages
   set deleted_by = '{}'::uuid[]
 where deleted_by is null;

-- Audio messages
alter table audio_messages
    add column if not exists deleted_by uuid[] default '{}'::uuid[];

alter table audio_messages
    add column if not exists deleted_for_everyone boolean default false;

alter table audio_messages
    add column if not exists deleted_at timestamptz;

update audio_messages
   set deleted_by = '{}'::uuid[]
 where deleted_by is null;

-- Delete for me (soft delete per user)
create or replace function delete_messages_for_me(
  p_user_id uuid,
  p_message_ids uuid[] default '{}',
  p_audio_message_ids uuid[] default '{}'
)
returns void
language plpgsql
security definer
as $$
begin
  if p_user_id is null then
    raise exception 'delete_messages_for_me requires authenticated user';
  end if;

  if array_length(p_message_ids, 1) > 0 then
    update messages
       set deleted_by = coalesce(deleted_by, '{}') || p_user_id
     where id = any(p_message_ids)
       and not coalesce(deleted_by, '{}') @> array[p_user_id];
  end if;

  if array_length(p_audio_message_ids, 1) > 0 then
    update audio_messages
       set deleted_by = coalesce(deleted_by, '{}') || p_user_id
     where id = any(p_audio_message_ids)
       and not coalesce(deleted_by, '{}') @> array[p_user_id];
  end if;
end;
$$;

-- Delete for everyone (strict 10 minute window, sender only)
create or replace function delete_messages_for_everyone(
  p_user_id uuid,
  p_message_ids uuid[] default '{}',
  p_audio_message_ids uuid[] default '{}'
)
returns void
language plpgsql
security definer
as $$
declare
  v_limit interval := interval '10 minutes';
begin
  if p_user_id is null then
    raise exception 'delete_messages_for_everyone requires authenticated user';
  end if;

  if array_length(p_message_ids, 1) > 0 then
    update messages
       set deleted_for_everyone = true,
           deleted_at = now()
     where id = any(p_message_ids)
       and sender_id = p_user_id
       and coalesce(deleted_for_everyone, false) = false
       and now() - created_at <= v_limit;
  end if;

  if array_length(p_audio_message_ids, 1) > 0 then
    update audio_messages
       set deleted_for_everyone = true,
           deleted_at = now()
     where id = any(p_audio_message_ids)
       and sender_id = p_user_id
       and coalesce(deleted_for_everyone, false) = false
       and now() - created_at <= v_limit;
  end if;
end;
$$;

