-- ============================================================
-- Milestone 20: Leaderboard (daily + weekly)
-- rank_points = focused_minutes + challenge_bonus + streak_bonus
--   focused_minutes : SUM(study_sessions.actual_minutes) in period
--   challenge_bonus : SUM(user_daily_challenges.rank_points) of
--                     claimed challenges in period
--   streak_bonus    : current_streak() days x 10, capped at 300
-- All date math is in UTC (Supabase default).
-- ============================================================

-- ---------- 1) indexes for the leaderboard queries ----------
create index if not exists study_sessions_ended_at_idx
    on public.study_sessions (ended_at);

create index if not exists study_sessions_user_ended_idx
    on public.study_sessions (user_id, ended_at desc);

create index if not exists study_sessions_user_completed_ended_idx
    on public.study_sessions (user_id, completed, ended_at);

create index if not exists udc_date_claimed_idx
    on public.user_daily_challenges (challenge_date, claimed);

-- ============================================================
-- 2) current_streak(user_id)
-- Consecutive days with at least one COMPLETED session, ending
-- today or yesterday (today doesn't count as a break yet).
-- ============================================================
create or replace function public.current_streak(p_user_id uuid)
returns integer
language sql
stable
security invoker
set search_path = public
as $$
    with session_days as (
        select distinct (ended_at::date) as d
          from public.study_sessions
         where user_id = p_user_id
           and completed
    ),
    grouped as (
        select d, d - (row_number() over (order by d))::integer as grp
          from session_days
    ),
    active_grp as (
        select grp from grouped where d in (current_date, current_date - 1) limit 1
    )
    select count(*)
      from grouped
     where grp = (select grp from active_grp);
$$;

grant execute on function public.current_streak(uuid) to authenticated;

-- ============================================================
-- 3) daily_leaderboard
-- Runs with the view owner's privileges (security_invoker =
-- false) on purpose: it must read every user's profile to rank
-- them, but it only exposes whitelisted columns (user_id,
-- display_name, avatar_url, points). No email/coins leak.
-- ============================================================
create or replace view public.daily_leaderboard
with (security_invoker = false)
as
with focused as (
    select user_id, coalesce(sum(actual_minutes), 0) as focused_minutes
      from public.study_sessions
     where ended_at >= current_date::timestamptz
       and ended_at <  (current_date + 1)::timestamptz
     group by user_id
),
challenge_bonus as (
    select user_id, coalesce(sum(rank_points), 0) as challenge_bonus
      from public.user_daily_challenges
     where claimed
       and challenge_date = current_date
     group by user_id
)
select p.user_id,
       p.display_name,
       p.avatar_url,
       coalesce(f.focused_minutes, 0)::integer                as focused_minutes,
       coalesce(c.challenge_bonus, 0)::integer                as challenge_bonus,
       s.streak_days,
       least(s.streak_days * 10, 300)::integer                as streak_bonus,
       (coalesce(f.focused_minutes, 0)
        + coalesce(c.challenge_bonus, 0)
        + least(s.streak_days * 10, 300))::integer            as rank_points
  from public.profiles p
  left join focused f on f.user_id = p.user_id
  left join challenge_bonus c on c.user_id = p.user_id
  left join lateral (select public.current_streak(p.user_id) as streak_days) s on true
 order by rank_points desc, p.display_name asc;

alter view public.daily_leaderboard set (security_invoker = false);

-- ============================================================
-- 4) weekly_leaderboard — same shape, rolling 7 days
-- ============================================================
create or replace view public.weekly_leaderboard
with (security_invoker = false)
as
with focused as (
    select user_id, coalesce(sum(actual_minutes), 0) as focused_minutes
      from public.study_sessions
     where ended_at >= (current_date - 6)::timestamptz
       and ended_at <  (current_date + 1)::timestamptz
     group by user_id
),
challenge_bonus as (
    select user_id, coalesce(sum(rank_points), 0) as challenge_bonus
      from public.user_daily_challenges
     where claimed
       and challenge_date between current_date - 6 and current_date
     group by user_id
)
select p.user_id,
       p.display_name,
       p.avatar_url,
       coalesce(f.focused_minutes, 0)::integer                as focused_minutes,
       coalesce(c.challenge_bonus, 0)::integer                as challenge_bonus,
       s.streak_days,
       least(s.streak_days * 10, 300)::integer                as streak_bonus,
       (coalesce(f.focused_minutes, 0)
        + coalesce(c.challenge_bonus, 0)
        + least(s.streak_days * 10, 300))::integer            as rank_points
  from public.profiles p
  left join focused f on f.user_id = p.user_id
  left join challenge_bonus c on c.user_id = p.user_id
  left join lateral (select public.current_streak(p.user_id) as streak_days) s on true
 order by rank_points desc, p.display_name asc;

alter view public.weekly_leaderboard set (security_invoker = false);

-- ============================================================
-- 5) read policy
-- The views are the ONLY exposure path: nothing is granted to
-- anon, authenticated users may only SELECT the two views, and
-- the views are security-definer so they ignore the (strict,
-- own-rows) RLS on profiles while leaking nothing sensitive.
-- ============================================================
revoke all on public.daily_leaderboard, public.weekly_leaderboard from public;
grant select on public.daily_leaderboard to authenticated;
grant select on public.weekly_leaderboard to authenticated;

-- ============================================================
-- 6) query examples
-- top 10 today:
--   select * from public.daily_leaderboard limit 10;
-- top 10 this week:
--   select * from public.weekly_leaderboard limit 10;
-- my current position (weekly):
--   select position, user_id, rank_points from (
--     select rank() over (order by rank_points desc) as position, *
--       from public.weekly_leaderboard
--   ) r where user_id = auth.uid();
-- what makes up my points:
--   select focused_minutes, challenge_bonus, streak_days,
--          streak_bonus, rank_points
--     from public.daily_leaderboard where user_id = auth.uid();
-- my current streak:
--   select public.current_streak(auth.uid());
-- ============================================================
