-- ============================================================
-- 0002_seed_categories.sql
-- Funkcia na naseedovanie default kategórií pre novú domácnosť.
-- Volaj po vytvorení household-u:
--   select seed_default_categories('<household_id>');
-- ============================================================

create or replace function public.seed_default_categories(p_household_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  -- Príjmové kategórie
  v_income text[] := array[
    'Mzda',
    'Podnikanie',
    'Odmeny',
    'Rodičovský príspevok',
    'Prídavky',
    'Prenájom',
    'Investície',
    'Dary',
    'Iné'
  ];
  -- Výdavkové kategórie
  v_expense text[] := array[
    'Bývanie',
    'Energie',
    'Internet a TV',
    'Potraviny',
    'Reštaurácie',
    'Doprava-PHM',
    'Doprava-MHD',
    'Servis auta',
    'Zdravie',
    'Lieky',
    'Deti-škola',
    'Deti-krúžky',
    'Oblečenie',
    'Drogéria',
    'Predplatné',
    'Mobil',
    'Dovolenky',
    'Kultúra',
    'Šport',
    'Darčeky',
    'Poistenie',
    'Sporenie',
    'Splátky úverov',
    'Bankové poplatky',
    'Dane',
    'Domáce zvieratá',
    'Iné'
  ];
  v_name text;
  v_i int;
begin
  -- Overenie, že volajúci má prístup k danej domácnosti
  if not exists (
    select 1 from public.household_members
    where household_id = p_household_id and user_id = auth.uid()
  ) then
    raise exception 'Not a member of household %', p_household_id
      using errcode = '42501';
  end if;

  v_i := 0;
  foreach v_name in array v_income loop
    insert into public.categories (household_id, name, type, display_order)
    values (p_household_id, v_name, 'income', v_i);
    v_i := v_i + 1;
  end loop;

  v_i := 0;
  foreach v_name in array v_expense loop
    insert into public.categories (household_id, name, type, display_order)
    values (p_household_id, v_name, 'expense', v_i);
    v_i := v_i + 1;
  end loop;
end;
$$;

-- Umožni volanie z klienta (RLS na categories chráni zápis)
grant execute on function public.seed_default_categories(uuid) to authenticated;
