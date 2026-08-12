-- ============================================================
-- Milestone 17: Store
-- Prices, equipped flag, hard duplicate protection, buy/equip
-- RPCs and idempotent starter grants.
-- ============================================================

-- 1) characters get a coin price (level gate stays on unlock_level)
alter table public.characters
    add column if not exists price_coins integer not null default 0 check (price_coins >= 0);

update public.characters set price_coins = 0 where is_starter;
update public.characters set price_coins = unlock_level * 100 where not is_starter;

-- 2) reward animations get a coin price
alter table public.reward_animations
    add column if not exists price_coins integer not null default 200 check (price_coins >= 0);

update public.reward_animations
   set price_coins = case animation_key
       when 'focus_flame' then 150
       when 'star_shower' then 250
       else 200
   end;

-- 3) inventory items carry their own equipped flag
alter table public.user_inventory
    add column if not exists is_equipped boolean not null default false;

create index if not exists user_inventory_user_idx
    on public.user_inventory (user_id, is_equipped);

-- 4) hard duplicate-purchase protection: one ownership row per item
create unique index if not exists uq_user_characters_owner
    on public.user_characters (user_id, character_id);

create unique index if not exists uq_user_inventory_owner
    on public.user_inventory (user_id, item_type, item_id);

-- ============================================================
-- Buy an item. One atomic transaction: validates the item, the
-- level gate, the balance, blocks duplicates, deducts coins,
-- records the purchase and grants ownership.
-- ============================================================
create or replace function public.buy_store_item(
    p_item_type text,
    p_item_id uuid
)
returns jsonb
language plpgsql
security invoker
as $$
declare
    v_user_id uuid := auth.uid();
    v_price integer := 0;
    v_balance integer;
    v_name text;
    v_level_gate integer := 0;
begin
    if v_user_id is null then
        raise exception 'not authenticated';
    end if;

    case p_item_type
        when 'character' then
            select price_coins, name, unlock_level into v_price, v_name, v_level_gate
              from public.characters
             where id = p_item_id and active;
        when 'background' then
            select price_coins, name into v_price, v_name
              from public.backgrounds
             where id = p_item_id and active;
        when 'timer_skin' then
            select price_coins, name into v_price, v_name
              from public.timer_skins
             where id = p_item_id and active;
        when 'reward_animation' then
            select price_coins, name into v_price, v_name
              from public.reward_animations
             where id = p_item_id and active;
        else
            raise exception 'unknown item type: %', p_item_type;
    end case;

    if v_name is null then
        raise exception 'item not found';
    end if;

    -- duplicate purchase
    if p_item_type = 'character' then
        if exists (select 1 from public.user_characters
                    where user_id = v_user_id and character_id = p_item_id) then
            raise exception 'already owned';
        end if;
    elsif exists (select 1 from public.user_inventory
                  where user_id = v_user_id and item_type = p_item_type and item_id = p_item_id) then
        raise exception 'already owned';
    end if;

    -- character level gate (unlock_level = 1 for starters, free anyway)
    if p_item_type = 'character' and v_level_gate > 1 then
        select profile_level into v_balance from public.profiles where user_id = v_user_id;
        if v_balance < v_level_gate then
            raise exception 'level too low';
        end if;
    end if;

    -- balance check
    select coins into v_balance from public.profiles where user_id = v_user_id;
    if v_balance < v_price then
        raise exception 'insufficient coins';
    end if;

    update public.profiles set coins = coins - v_price where user_id = v_user_id;

    insert into public.store_purchases (user_id, item_type, item_id, price_coins)
    values (v_user_id, p_item_type, p_item_id, v_price);

    if p_item_type = 'character' then
        insert into public.user_characters (user_id, character_id, is_selected, xp)
        values (v_user_id, p_item_id, false, 0);
    else
        insert into public.user_inventory (user_id, item_type, item_id, is_equipped)
        values (v_user_id, p_item_type, p_item_id, false);
    end if;

    return jsonb_build_object('price_coins', v_price, 'balance', v_balance - v_price);
end;
$$;

grant execute on function public.buy_store_item(text, uuid) to authenticated;

-- ============================================================
-- Equip one owned inventory item (background / timer skin /
-- reward animation). Unequips the previous one of the same
-- type.
-- ============================================================
create or replace function public.equip_inventory_item(
    p_item_type text,
    p_item_id uuid
)
returns void
language plpgsql
security invoker
as $$
begin
    if not exists (
        select 1 from public.user_inventory
         where user_id = auth.uid()
           and item_type = p_item_type
           and item_id = p_item_id
    ) then
        raise exception 'item not owned';
    end if;

    update public.user_inventory
       set is_equipped = (item_id = p_item_id)
     where user_id = auth.uid()
       and item_type = p_item_type;
end;
$$;

grant execute on function public.equip_inventory_item(text, uuid) to authenticated;

-- ============================================================
-- Idempotent starter kit for new sign-ups: the starter
-- character (equipped, form 1) plus the starter background and
-- timer skin (equipped). Reruns safe thanks to the unique
-- indexes above.
-- ============================================================
create or replace function public.grant_starter_items()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.user_characters (user_id, character_id, is_selected, xp, form_unlocked)
    select new.id, c.id, true, 0,
           (select f.form_order from public.character_forms f
             where f.character_id = c.id and f.form_order = 1 limit 1)
      from public.characters c
     where c.is_starter and c.active
     limit 1
    on conflict do nothing;

    insert into public.user_inventory (user_id, item_type, item_id, is_equipped)
    select new.id, 'background', b.id, true
      from public.backgrounds b
     where b.is_starter and b.active
     limit 1
    on conflict do nothing;

    insert into public.user_inventory (user_id, item_type, item_id, is_equipped)
    select new.id, 'timer_skin', s.id, true
      from public.timer_skins s
     where s.is_starter and s.active
     limit 1
    on conflict do nothing;

    return new;
end;
$$;

-- Attach the grant trigger to auth.users if it isn't already there.
do $$
begin
    if not exists (select 1 from pg_trigger where tgname = 'on_auth_user_created') then
        execute 'create trigger on_auth_user_created after insert on auth.users for each row execute function public.grant_starter_items()';
    end if;
end $$;
