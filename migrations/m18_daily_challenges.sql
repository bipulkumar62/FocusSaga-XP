-- ============================================================
-- Milestone 18: Daily challenges
-- Static templates (daily_challenges) + per-user per-day rows
-- (user_daily_challenges). Progress is computed from live data
-- by refresh_daily_challenges(); rewards are claimed via
-- claim_challenge_reward(). "Reset" is automatic: rows are
-- scoped to challenge_date, so a new day simply means new rows.
-- ============================================================

-- ---------- 1) templates ----------
create table if not exists public.daily_challenges (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    description text not null,
    metric text not null check (
        metric in ('study_minutes', 'complete_sessions', 'no_pause_session', 'level_up_character', 'use_background')
    ),
    target_value integer not null check (target_value > 0),
    reward_coins integer not null default 20 check (reward_coins >= 0),
    active boolean not null default true,
    created_at timestamptz not null default now()
);

create unique index if not exists uq_daily_challenges_title on public.daily_challenges (title);

-- ---------- 2) per-user per-day rows ----------
create table if not exists public.user_daily_challenges (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    challenge_id uuid not null references public.daily_challenges (id) on delete cascade,
    challenge_date date not null,
    target_value integer not null,
    reward_coins integer not null default 20,
    progress integer not null default 0,
    is_completed boolean not null default false,
    claimed boolean not null default false,
    created_at timestamptz not null default now(),
    unique (user_id, challenge_date, challenge_id)
);

create index if not exists uqdc_user_date_idx
    on public.user_daily_challenges (user_id, challenge_date desc, is_completed);

-- ---------- 3) RLS ----------
alter table public.daily_challenges enable row level security;
alter table public.user_daily_challenges enable row level security;

-- templates: readable by every signed-in user, not writable
create policy "challenges are public to authenticated"
    on public.daily_challenges for select
    to authenticated
    using (true);

-- per-user rows: own rows only, readable; every write happens through the
-- SECURITY DEFINER RPCs below (no insert/update/delete policies on purpose)
create policy "users read own daily challenges"
    on public.user_daily_challenges for select
    to authenticated
    using (auth.uid() = user_id);

-- ---------- 4) seed templates ----------
insert into public.daily_challenges (title, description, metric, target_value, reward_coins)
values
    ('Focus Sprint', 'Study for 25 minutes today.', 'study_minutes', 25, 20),
    ('Deep Work', 'Study for a full hour today.', 'study_minutes', 60, 40),
    ('Marathon Mind', 'Study for 2 hours today.', 'study_minutes', 120, 80),
    ('Clean Finish', 'Complete 2 focus sessions today.', 'complete_sessions', 2, 20),
    ('Hat Trick', 'Complete 3 focus sessions today.', 'complete_sessions', 3, 30),
    ('No Interruptions', 'Finish a session without pausing.', 'no_pause_session', 1, 25),
    ('Rising Star', 'Level up a character today.', 'level_up_character', 1, 50),
    ('Fresh Scenery', 'Equip a background that is not the starter one.', 'use_background', 1, 15)
on conflict (title) do nothing;

-- ============================================================
-- 5) refresh_daily_challenges()
-- Assigns today's 3 challenges (rotating by day + user) if
-- missing, recomputes progress from live data, and returns the
-- day's rows as jsonb for the app.
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

    -- rotate by day-of-year plus a small per-user nudge so the three
    -- selected challenges differ between users but are deterministic
    v_offset := (extract(doy from v_today)::int * 3 + abs(hashtext(v_user_id::text)) % 7) % v_total;

    insert into public.user_daily_challenges
        (user_id, challenge_id, challenge_date, target_value, reward_coins)
    select v_user_id, c.id, v_today, c.target_value, c.reward_coins
      from (
          select id, (row_number() over (order by id) - 1 + v_offset) % v_total as slot
            from public.daily_challenges
           where active
      ) c
     where c.slot < 3
    on conflict (user_id, challenge_date, challenge_id) do nothing;

    -- live metrics for today
    select coalesce(sum(actual_minutes), 0),
           count(*) filter (where completed),
           count(*) filter (where completed and paused_count = 0),
           coalesce(sum(coins_earned), 0) / 20   -- levels cleared today
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
               u.target_value, u.reward_coins, u.claimed
          from public.user_daily_challenges u
          join public.daily_challenges c on c.id = u.challenge_id
         where u.user_id = v_user_id
           and u.challenge_date = v_today
    loop
        declare
            v_progress integer := 0;
        begin
            case r.metric
                when 'study_minutes'     then v_progress := v_minutes;
                when 'complete_sessions' then v_progress := v_completed_sessions;
                when 'no_pause_session'  then v_progress := v_no_pause;
                when 'level_up_character' then v_progress := v_levels;
                when 'use_background'    then v_progress := case when v_use_background then 1 else 0 end;
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
                'reward_coins', r.reward_coins
            );
        end;
    end loop;

    return v_result;
end;
$$;

grant execute on function public.refresh_daily_challenges() to authenticated;

-- ============================================================
-- 6) claim_challenge_reward()
-- Validates ownership + completion + not-yet-claimed, then adds
-- the coins to the profile. SECURITY DEFINER so there is no
-- direct row-update path for the app.
-- ============================================================
create or replace function public.claim_challenge_reward(p_user_challenge_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_reward integer;
    v_is_completed boolean;
    v_claimed boolean;
    v_balance integer;
begin
    if v_user_id is null then
        raise exception 'not authenticated';
    end if;

    select u.reward_coins, u.is_completed, u.claimed
      into v_reward, v_is_completed, v_claimed
      from public.user_daily_challenges u
     where u.id = p_user_challenge_id
       and u.user_id = v_user_id;

    if v_reward is null then
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
       set coins = coins + v_reward
     where user_id = v_user_id
     returning coins into v_balance;

    return jsonb_build_object('reward_coins', v_reward, 'balance', v_balance);
end;
$$;

grant execute on function public.claim_challenge_reward(uuid) to authenticated;

-- ============================================================
-- 7) Reset strategy
-- Daily rows are date-scoped: refresh_daily_challenges() only
-- ever touches current_date, so old days are immutable history
-- (useful for stats/rankings later). Optional pruning of
-- history older than 30 days via pg_cron (skip this if you do
-- not want to enable the extension).
-- ============================================================
do $do$
begin
    if exists (select 1 from pg_extension where extname = 'pg_cron') then
        begin
            perform cron.unschedule('prune-old-daily-challenges');
        exception when others then
            null; -- job did not exist yet
        end;
        perform cron.schedule(
            'prune-old-daily-challenges',
            '0 3 * * *',
            $$delete from public.user_daily_challenges where challenge_date < current_date - 30$$
        );
    end if;
end $do$;
