-- Anonymous guest auth: give anonymous users a friendly fallback name.
-- Google sign-in users keep their display_name / email as before.

-- 1) handle_new_user creates the profile; anonymous guests (no email,
--    no metadata) get 'Guest Learner' instead of the email prefix.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (user_id, display_name, email, avatar_url)
    values (
        new.id,
        coalesce(
            new.raw_user_meta_data->>'display_name',
            case when new.email is null then 'Guest Learner'
                 else split_part(new.email, '@', 1)
            end
        ),
        new.email,
        new.raw_user_meta_data->>'avatar_url'
    );
    insert into public.terms_acceptance (user_id) values (new.id);
    perform public.grant_starter_items(new.id);
    return new;
end;
$$;

-- 2) Fix profiles created before this change (anonymous users fell back to
--    the generic 'user' name). Only touches email-less profiles, so real
--    Google users are never renamed.
update public.profiles
   set display_name = 'Guest Learner'
 where display_name = 'user'
   and email is null;
