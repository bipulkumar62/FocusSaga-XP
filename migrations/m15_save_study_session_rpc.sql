-- Milestone 15: atomic session save + reward application.
-- One database call does everything: compute XP, level up, award coins,
-- persist the study session. RLS (security invoker) means users can only
-- ever touch their own rows, even inside the function.

create or replace function public.save_study_session(
    p_planned_minutes integer,
    p_actual_minutes integer,
    p_completed boolean,
    p_paused_count integer default 0,
    p_character_id uuid default null,
    p_started_at timestamptz default null,
    p_ended_at timestamptz default null
)
returns jsonb
language plpgsql
security invoker
as $$
declare
    v_user_id uuid := auth.uid();
    v_planned integer := greatest(p_planned_minutes, 0);
    v_actual integer;
    v_xp integer;
    v_level_before integer;
    v_level_after integer;
    v_coins_earned integer;
    v_char_id uuid;
    v_xp_after integer;
    v_session_id uuid;
begin
    if v_user_id is null then
        raise exception 'not authenticated';
    end if;

    -- a session can never exceed its plan (mirrors the app-side clamp)
    v_actual := greatest(least(p_actual_minutes, v_planned), 0);

    -- 1 actual minute = 1 XP; +20% when completed fully
    v_xp := round(v_actual * (case when p_completed then 1.2 else 1 end))::integer;

    -- resolve the character: explicit id > selected > starter (granted on the fly)
    select uc.id, uc.xp into v_char_id, v_xp_after
      from public.user_characters uc
     where uc.user_id = v_user_id
       and (p_character_id is null or uc.id = p_character_id)
       and (p_character_id is not null or uc.is_selected)
     order by (p_character_id is not null) desc, uc.is_selected desc
     limit 1;

    if v_char_id is null then
        insert into public.user_characters (user_id, character_id, is_selected, xp)
        select v_user_id, c.id, true, 0
          from public.characters c
         where c.is_starter
         order by c.id
         limit 1
        returning id into v_char_id;
        v_xp_after := 0;
    end if;

    -- level curve: level = xp / 100 + 1, capped at 50 (integer division)
    v_level_before := least(v_xp_after / 100 + 1, 50);
    v_xp_after := v_xp_after + v_xp;
    v_level_after := least(v_xp_after / 100 + 1, 50);

    -- every cleared level = +20 coins
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
         where user_id = v_user_id;
    end if;

    insert into public.study_sessions
        (user_id, planned_minutes, actual_minutes, started_at, ended_at,
         completed, paused_count, xp_earned, coins_earned)
    values
        (v_user_id, v_planned, v_actual,
         coalesce(p_started_at, now() - make_interval(mins => v_actual)),
         coalesce(p_ended_at, now()),
         p_completed, greatest(p_paused_count, 0), v_xp, v_coins_earned)
    returning id into v_session_id;

    return jsonb_build_object(
        'session_id', v_session_id,
        'xp_earned', v_xp,
        'coins_earned', v_coins_earned,
        'character_id', v_char_id,
        'character_xp_before', v_xp_after - v_xp,
        'character_xp_after', v_xp_after,
        'character_level_before', v_level_before,
        'character_level_after', v_level_after,
        'levels_gained', v_level_after - v_level_before
    );
end;
$$;

grant execute on function public.save_study_session(integer, integer, boolean, integer, uuid, timestamptz, timestamptz) to authenticated;
