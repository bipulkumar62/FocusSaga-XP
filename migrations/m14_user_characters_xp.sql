-- Milestone 14: character XP lives on user_characters
alter table public.user_characters
    add column if not exists xp integer not null default 0 check (xp >= 0);

create index if not exists user_characters_xp_idx
    on public.user_characters (user_id, xp desc);

-- RLS already covers user_characters (own rows only), so the new column is
-- protected automatically. No policy changes needed.
