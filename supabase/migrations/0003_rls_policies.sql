-- ============================================================
-- 0003_rls_policies.sql
-- RLS politiky: user vidí len dáta domácností, kde je členom.
-- Helper: user_household_ids() — všetky household_id pre auth.uid().
--
-- Pozn. k households_insert/select:
--   Onboarding flow robí `insert().select().single()`, čo vyžaduje,
--   aby INSERT i SELECT policy prepustili ten istý riadok. User v
--   momente insertu ešte NIE je v household_members (pridáva sa
--   hneď potom), preto:
--     - INSERT: povolíme všetkým authenticated, created_by sa vyplní
--       triggerom nižšie (nedá sa podhodiť cudzí uid).
--     - SELECT: povolíme členom ALEBO creatorovi (fallback pre
--       `... RETURNING` pri insertoch).
-- ============================================================

-- ------------------------------------------------------------
-- Helper funkcia
--   SECURITY DEFINER + STABLE + fixed search_path pre bezpečné
--   používanie v RLS politikách bez rekurzie.
-- ------------------------------------------------------------
create or replace function public.user_household_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select household_id
  from public.household_members
  where user_id = auth.uid();
$$;

grant execute on function public.user_household_ids() to authenticated;

-- ------------------------------------------------------------
-- Trigger: pri INSERT do households automaticky doplniť
--   created_by = auth.uid() (zabraňuje podhodeniu cudzieho uid).
-- ------------------------------------------------------------
create or replace function public.households_set_created_by()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.created_by := auth.uid();
  return new;
end;
$$;

drop trigger if exists trg_households_created_by on public.households;
create trigger trg_households_created_by
  before insert on public.households
  for each row execute function public.households_set_created_by();

-- ------------------------------------------------------------
-- Zapnutie RLS na všetkých tabuľkách
-- ------------------------------------------------------------
alter table public.households          enable row level security;
alter table public.household_members   enable row level security;
alter table public.accounts            enable row level security;
alter table public.categories          enable row level security;
alter table public.transactions        enable row level security;
alter table public.recurring_templates enable row level security;
alter table public.budgets             enable row level security;

-- ============================================================
-- households
-- ============================================================
create policy "households_select"
  on public.households for select
  using (
    id in (select public.user_household_ids())
    or created_by = auth.uid()
  );

create policy "households_insert"
  on public.households for insert
  to authenticated
  with check (auth.uid() is not null);

create policy "households_update"
  on public.households for update
  using (
    id in (
      select household_id from public.household_members
      where user_id = auth.uid() and role in ('owner','admin')
    )
  );

create policy "households_delete"
  on public.households for delete
  using (
    id in (
      select household_id from public.household_members
      where user_id = auth.uid() and role = 'owner'
    )
  );

-- ============================================================
-- household_members
-- ============================================================
create policy "household_members_select"
  on public.household_members for select
  using (household_id in (select public.user_household_ids()));

-- Umožní 1) ownerovi/adminovi pridávať členov, 2) userovi sa zaradiť
-- pri vytvorení vlastnej domácnosti (žiaden člen ešte neexistuje).
create policy "household_members_insert"
  on public.household_members for insert
  with check (
    user_id = auth.uid()
    or household_id in (
      select hm.household_id from public.household_members hm
      where hm.user_id = auth.uid() and hm.role in ('owner','admin')
    )
  );

create policy "household_members_update"
  on public.household_members for update
  using (
    household_id in (
      select hm.household_id from public.household_members hm
      where hm.user_id = auth.uid() and hm.role in ('owner','admin')
    )
  );

create policy "household_members_delete"
  on public.household_members for delete
  using (
    user_id = auth.uid()
    or household_id in (
      select hm.household_id from public.household_members hm
      where hm.user_id = auth.uid() and hm.role in ('owner','admin')
    )
  );

-- ============================================================
-- accounts
-- ============================================================
create policy "accounts_select"
  on public.accounts for select
  using (household_id in (select public.user_household_ids()));

create policy "accounts_insert"
  on public.accounts for insert
  with check (household_id in (select public.user_household_ids()));

create policy "accounts_update"
  on public.accounts for update
  using (household_id in (select public.user_household_ids()));

create policy "accounts_delete"
  on public.accounts for delete
  using (household_id in (select public.user_household_ids()));

-- ============================================================
-- categories
-- ============================================================
create policy "categories_select"
  on public.categories for select
  using (household_id in (select public.user_household_ids()));

create policy "categories_insert"
  on public.categories for insert
  with check (household_id in (select public.user_household_ids()));

create policy "categories_update"
  on public.categories for update
  using (household_id in (select public.user_household_ids()));

create policy "categories_delete"
  on public.categories for delete
  using (household_id in (select public.user_household_ids()));

-- ============================================================
-- transactions
-- ============================================================
create policy "transactions_select"
  on public.transactions for select
  using (household_id in (select public.user_household_ids()));

create policy "transactions_insert"
  on public.transactions for insert
  with check (household_id in (select public.user_household_ids()));

create policy "transactions_update"
  on public.transactions for update
  using (household_id in (select public.user_household_ids()));

create policy "transactions_delete"
  on public.transactions for delete
  using (household_id in (select public.user_household_ids()));

-- ============================================================
-- recurring_templates
-- ============================================================
create policy "recurring_templates_select"
  on public.recurring_templates for select
  using (household_id in (select public.user_household_ids()));

create policy "recurring_templates_insert"
  on public.recurring_templates for insert
  with check (household_id in (select public.user_household_ids()));

create policy "recurring_templates_update"
  on public.recurring_templates for update
  using (household_id in (select public.user_household_ids()));

create policy "recurring_templates_delete"
  on public.recurring_templates for delete
  using (household_id in (select public.user_household_ids()));

-- ============================================================
-- budgets
-- ============================================================
create policy "budgets_select"
  on public.budgets for select
  using (household_id in (select public.user_household_ids()));

create policy "budgets_insert"
  on public.budgets for insert
  with check (household_id in (select public.user_household_ids()));

create policy "budgets_update"
  on public.budgets for update
  using (household_id in (select public.user_household_ids()));

create policy "budgets_delete"
  on public.budgets for delete
  using (household_id in (select public.user_household_ids()));
