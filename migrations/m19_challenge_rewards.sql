-- ============================================================
-- Milestone 19: challenge rewards now include XP and rank
-- points, in addition to coins.
-- - daily_challenges / user_daily_challenges gain reward_xp +
--   rank_points (snapshot at assignment time)
-- - profiles gains rank_points (ranking system later)
-- - apply_character_xp() helper: adds XP to the equipped
--   character, handles level-ups + +20 coins/level + form unlock
-- - refresh_daily_challenges() snapshots the new rewards
-- - claim_challenge_reward() pays coins + rank points and calls
--   apply_character_xp() for the XP part
-- ============================================================

-- ---------- 1) new columns ----------
alter table public.daily_challenges
    add column if not exists reward_xp integer not null default 0 check (reward_xp >= 0),
    add column if not exists rank_points integer not null default 0 check (rank_points >= 0);

alter table public.user_daily_challenges
    add column if not exists reward_xp integer not null default 0,
    add column if not exists rank_points integer not null default 0;

alter table public.profiles
    add column if not exists rank_points integer not null default 0 check (rank_points >= 0);

-- ---------- 2) reward values on the seeded templates ----------
update public.daily_challenges d
   set reward_xp = s.reward_xp,
       rank_points = s.rank_points
  from (values
    ('Focus Sprint',     10,  5),
    ('Deep Work',        25, 10),
    ('Marathon Mind',    50, 20),
    ('Clean Finish',     15,  8),
    ('Hat Trick',        20, 10),
    ('No Interruptions', 15,  8),
    ('Rising Star',      30, 15),
    ('Fresh Scenery',    10,  5)
  ) as s(title, reward_xp, rank_points)
 where d.title = s.title;

-- ============================================================
-- 3) apply_character_xp(p_user_id, p_xp)
-- Shared by reward-claiming paths: adds XP to the equipped
-- character, recomputes level, unlocks the best reached form and
-- pays +20 coins per cleared level.
-- ============================================================
create or replace function public.apply_character_xp(p_user_id uuid, p_xp integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_char_id uuid;
    v_xp_before integer;
    v_xp_after integer;
    v_level_before integer;
    v_level_after integer;
    v_coins_earned integer := 0;
begin
    if p_xp <= 0 then
        return jsonb_build_object(
            'character_id', null,
            'character_level_after', null,
            'levels_gained', 0,
            'coins_earned', 0
        );
    end if;

    select uc.id, uc.xp into v_char_id, v_xp_before
      from public.user_characters uc
     where uc.user_id = p_user_id and uc.is_selected
     limit 1;

    if v_char_id is null then
        insert into public.user_characters (user_id, character_id, is_selected, xp)
        select p_user_id, c.id, true, 0
          from public.characters c
         where c.is_starter and c.active
         order by c.id
         limit 1
        returning id into v_char_id;
        v_xp_before := 0;
    end if;

    v_level_before := least(v_xp_before / 100 + 1, 50);
    v_xp_after := v_xp_before + p_xp;
    v_level_after := least(v_xp_after / 100 + 1, 50);
    v_coins_earned := greatest(v_level_after - v_level_before, 0) * 20;

    update public.user_characters
       set xp = v_xp_after,
           form_unlocked = coalesce(
               (select f.form_order
                  from public.character_forms f
                  join public.user_characters uc on uc.character_id = f.character_id
                 where uc.id = v_char_id
                   and f.unlock_level <= v_level_after
                 order by f.unlock_level desc, f.id
                 limit 1),
               form_unlocked
           )
     where id = v_char_id;

    if v_coins_earned > 0 then
        update public.profiles
           set coins = coins + v_coins_earned,
               profile_level = v_level_after
         where user_id = p_user_id;
    end if;

    return jsonb_build_object(
        'character_id', v_char_id,
        'character_level_after', v_level_after,
        'levels_gained', v_level_after - v_level_before,
        'coins_earned', v_coins_earned
    );
end;
$$;

-- ============================================================
-- 4) refresh_daily_challenges() — now snapshots XP + rank points
-- ============================================================
create or replace function public.refresh_daily_challenges()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_today date := current_date;
    v_start timestamptz := v_today::timestamptz;
    v_end timestamptz := (v_today + 1)::timestamptz;
    v_total integer;
    v_offset integer;
    v_minutes integer := 0;
    v_completed_sessions integer := 0;
    v_no_pause integer := 0;
    v_levels integer := 0;
    v_use_background boolean := false;
    r record;
    v_result jsonb := '[]'::jsonb;
begin
    if v_user_id is null then
        raise exception 'not authenticated';
    end if;

    select count(*) into v_total from public.daily_challenges where active;
    if v_total = 0 then
        return '[]'::jsonb;
    end if;

    v_offset := (extract(doy from v_today)::int * 3 + abs(hashtext(v_user_id::text)) % 7) % v_total;

    insert into public.user_daily_challenges
        (user_id, challenge_id, challenge_date, target_value, reward_coins, reward_xp, rank_points)
    select v_user_id, t.id, v_today, t.target_value, t.reward_coins, t.reward_xp, t.rank_points
      from (
          select id, (row_number() over (order by id) - 1 + v_offset) % v_total as slot
            from public.daily_challenges
           where active
      ) c
      join public.daily_challenges t on t.id = c.id
     where c.slot < 3
    on conflict (user_id, challenge_date, challenge_id) do nothing;

    select coalesce(sum(actual_minutes), 0),
           count(*) filter (where completed),
           count(*) filter (where completed and paused_count = 0),
           coalesce(sum(coins_earned), 0) / 20
      into v_minutes, v_completed_sessions, v_no_pause, v_levels
      from public.study_sessions
     where user_id = v_user_id
       and ended_at >= v_start
       and ended_at < v_end;

    select exists (
        select 1
          from public.user_inventory ui
          join public.backgrounds b on b.id = ui.item_id
         where ui.user_id = v_user_id
           and ui.item_type = 'background'
           and ui.is_equipped
           and not b.is_starter
    ) into v_use_background;

    for r in
        select u.id as user_challenge_id, c.title, c.description, c.metric,
               u.target_value, u.reward_coins, u.reward_xp, u.rank_points, u.claimed
          from public.user_daily_challenges u
          join public.daily_challenges c on c.id = u.challenge_id
         where u.user_id = v_user_id
           and u.challenge_date = v_today
    loop
        declare
            v_progress integer := 0;
        begin
            case r.metric
                when 'study_minutes'      then v_progress := v_minutes;
                when 'complete_sessions'  then v_progress := v_completed_sessions;
                when 'no_pause_session'   then v_progress := v_no_pause;
                when 'level_up_character' then v_progress := v_levels;
                when 'use_background'     then v_progress := case when v_use_background then 1 else 0 end;
                else v_progress := 0;
            end case;

            update public.user_daily_challenges
               set progress = v_progress,
                   is_completed = (v_progress >= r.target_value)
             where id = r.user_challenge_id;

            v_result := v_result || jsonb_build_object(
                'id', r.user_challenge_id,
                'title', r.title,
                'description', r.description,
                'metric', r.metric,
                'target_value', r.target_value,
                'progress', v_progress,
                'is_completed', v_progress >= r.target_value,
                'claimed', r.claimed,
                'reward_coins', r.reward_coins,
                'reward_xp', r.reward_xp,
                'rank_points', r.rank_points
            );
        end;
    end loop;

    return v_result;
end;
$$;

grant execute on function public.refresh_daily_challenges() to authenticated;

-- ============================================================
-- 5) claim_challenge_reward() — pays coins + rank points, then
-- routes the XP through apply_character_xp()
-- ============================================================
create or replace function public.claim_challenge_reward(p_user_challenge_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_coins integer;
    v_xp integer;
    v_rp integer;
    v_is_completed boolean;
    v_claimed boolean;
    v_balance integer;
    v_xp_result jsonb;
begin
    if v_user_id is null then
        raise exception 'not authenticated';
    end if;

    select u.reward_coins, u.reward_xp, u.rank_points, u.is_completed, u.claimed
      into v_coins, v_xp, v_rp, v_is_completed, v_claimed
      from public.user_daily_challenges u
     where u.id = p_user_challenge_id
       and u.user_id = v_user_id;

    if v_coins is null then
        raise exception 'challenge not found';
    end if;
    if not v_is_completed then
        raise exception 'challenge not completed';
    end if;
    if v_claimed then
        raise exception 'already claimed';
    end if;

    update public.user_daily_challenges
       set claimed = true
     where id = p_user_challenge_id;

    update public.profiles
       set coins = coins + v_coins,
           rank_points = rank_points + v_rp
     where user_id = v_user_id
     returning coins into v_balance;

    v_xp_result := public.apply_character_xp(v_user_id, v_xp);

    return jsonb_build_object(
        'reward_coins', v_coins,
        'reward_xp', v_xp,
        'rank_points', v_rp,
        'balance', v_balance,
        'character_level_after', (v_xp_result->>'character_level_after')::integer,
        'levels_gained', (v_xp_result->>'levels_gained')::integer,
        'level_up_coins', (v_xp_result->>'coins_earned')::integer
    );
end;
$$;

grant execute on function public.claim_challenge_reward(uuid) to authenticated;
