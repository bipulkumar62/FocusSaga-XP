-- Milestone 16: equip a character (atomically un-equips the rest).

create or replace function public.equip_character(p_user_character_id uuid)
returns void
language plpgsql
security invoker
as $$
begin
    if not exists (
        select 1
          from public.user_characters
         where user_id = auth.uid()
           and id = p_user_character_id
    ) then
        raise exception 'character not owned';
    end if;

    update public.user_characters
       set is_selected = (id = p_user_character_id)
     where user_id = auth.uid();
end;
$$;

grant execute on function public.equip_character(uuid) to authenticated;
