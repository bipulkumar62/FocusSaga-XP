-- ============================================================
-- Milestone 26: Starter-item repair
--
-- Idempotent repair for users who are missing pieces of the
-- starter kit (e.g. sign-ups before the grant trigger, failed
-- grants, or data drift). Guarantees:
--   * profile exists (50 coins, level 1)
--   * starter character owned, form 1 unlocked, selected when
--     the user has no selected character
--   * starter background owned and equipped when the user has
--     no equipped background
--   * starter timer skin owned and equipped when the user has
--     no equipped timer skin
-- Safe to run on every app start.
-- ============================================================

-- Characters never carried their own art; forms do. Keep the
-- column absent-compatible by adding it for parity with the
-- other master tables (avatars fall back to a placeholder icon).
alter table public.characters
    add column if not exists image_url text;

create or replace function public.ensure_starter_items_for_current_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_starter uuid;
    v_forms_first integer;
begin
    if v_user_id is null then
        raise exception 'not authenticated';
    end if;

    -- 1) profile (defaults: coins 50, level 1, tutorial not completed)
    insert into public.profiles (user_id)
    values (v_user_id)
    on conflict (user_id) do nothing;

    -- 2) starter character
    select c.id into v_starter
      from public.characters c
     where c.is_starter and c.active
     order by c.price_coins asc
     limit 1;

    if v_starter is not null then
        select f.form_order into v_forms_first
          from public.character_forms f
         where f.character_id = v_starter
           and f.form_order = 1
         limit 1;

        insert into public.user_characters
            (user_id, character_id, is_selected, xp, form_unlocked)
        values
            (v_user_id, v_starter, false, 0, coalesce(v_forms_first, 1))
        on conflict (user_id, character_id) do nothing;

        -- exactly one selected character; prefer the starter when none
        if not exists (
            select 1 from public.user_characters
             where user_id = v_user_id and is_selected
        ) then
            update public.user_characters
               set is_selected = true
             where user_id = v_user_id
               and character_id = v_starter;
        end if;
    end if;

    -- 3) starter background (equipped when nothing of the type is)
    insert into public.user_inventory (user_id, item_type, item_id, is_equipped)
    select v_user_id, 'background', b.id,
           not exists (
               select 1 from public.user_inventory ui
                where ui.user_id = v_user_id
                  and ui.item_type = 'background'
                  and ui.is_equipped
           )
      from public.backgrounds b
     where b.is_starter and b.active
       and not exists (
           select 1 from public.user_inventory ui
            where ui.user_id = v_user_id
              and ui.item_type = 'background'
              and ui.item_id = b.id
       )
     limit 1;

    if not exists (
        select 1 from public.user_inventory
         where user_id = v_user_id
           and item_type = 'background'
           and is_equipped
    ) then
        update public.user_inventory ui
           set is_equipped = true
         where ui.user_id = v_user_id
           and ui.item_type = 'background'
           and ui.item_id = (
               select b.id from public.backgrounds b
                where b.is_starter and b.active
                limit 1
           );
    end if;

    -- 4) starter timer skin (equipped when nothing of the type is)
    insert into public.user_inventory (user_id, item_type, item_id, is_equipped)
    select v_user_id, 'timer_skin', t.id,
           not exists (
               select 1 from public.user_inventory ui
                where ui.user_id = v_user_id
                  and ui.item_type = 'timer_skin'
                  and ui.is_equipped
           )
      from public.timer_skins t
     where t.is_starter and t.active
       and not exists (
           select 1 from public.user_inventory ui
            where ui.user_id = v_user_id
              and ui.item_type = 'timer_skin'
              and ui.item_id = t.id
       )
     limit 1;

    if not exists (
        select 1 from public.user_inventory
         where user_id = v_user_id
           and item_type = 'timer_skin'
           and is_equipped
    ) then
        update public.user_inventory ui
           set is_equipped = true
         where ui.user_id = v_user_id
           and ui.item_type = 'timer_skin'
           and ui.item_id = (
               select t.id from public.timer_skins t
                where t.is_starter and t.active
                limit 1
           );
    end if;
end;
$$;

grant execute on function public.ensure_starter_items_for_current_user() to authenticated;

-- ============================================================
-- The signup path (handle_new_user) calls grant_starter_items(uuid),
-- which predates the equipped-flag and form_unlocked columns, so new
-- users were granted un-equipped, form-1-default starters. Align the
-- uuid overload with the trigger version: form 1 unlocked and the
-- starter background/skin equipped out of the box.
-- ============================================================
create or replace function public.grant_starter_items(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.user_characters (user_id, character_id, is_selected, xp, form_unlocked)
    select p_user_id, c.id, true, 0,
           (select f.form_order from public.character_forms f
             where f.character_id = c.id and f.form_order = 1 limit 1)
      from public.characters c
     where c.is_starter and c.active
     limit 1
    on conflict (user_id, character_id) do nothing;

    insert into public.user_inventory (user_id, item_type, item_id, is_equipped)
    select p_user_id, 'background', b.id, true
      from public.backgrounds b
     where b.is_starter and b.active
     limit 1
    on conflict do nothing;

    insert into public.user_inventory (user_id, item_type, item_id, is_equipped)
    select p_user_id, 'timer_skin', s.id, true
      from public.timer_skins s
     where s.is_starter and s.active
     limit 1
    on conflict do nothing;
end;
$$;

grant execute on function public.grant_starter_items(uuid) to authenticated;
