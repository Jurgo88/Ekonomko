-- ============================================================
-- 0001_initial_schema.sql
-- Základná schéma pre rodinný rozpočet.
-- ============================================================

-- gen_random_uuid()
create extension if not exists "pgcrypto";

-- Trigger funkcia na updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ------------------------------------------------------------
-- households
-- ------------------------------------------------------------
create table public.households (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  currency    text not null default 'EUR',
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users(id) on delete set null
);

-- ------------------------------------------------------------
-- household_members
-- ------------------------------------------------------------
create table public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         text not null check (role in ('owner','admin','member')),
  joined_at    timestamptz not null default now(),
  primary key (household_id, user_id)
);

create index idx_household_members_user on public.household_members(user_id);

-- ------------------------------------------------------------
-- accounts
-- ------------------------------------------------------------
create table public.accounts (
  id              uuid primary key default gen_random_uuid(),
  household_id    uuid not null references public.households(id) on delete cascade,
  name            text not null,
  type            text not null check (type in ('checking','savings','cash','credit_card','investment','other')),
  currency        text not null default 'EUR',
  initial_balance numeric(14,2) not null default 0,
  color           text,
  icon            text,
  is_archived     boolean not null default false,
  display_order   int not null default 0,
  created_at      timestamptz not null default now()
);

create index idx_accounts_household on public.accounts(household_id);

-- ------------------------------------------------------------
-- categories
-- ------------------------------------------------------------
create table public.categories (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references public.households(id) on delete cascade,
  name          text not null,
  type          text not null check (type in ('income','expense')),
  color         text,
  icon          text,
  parent_id     uuid references public.categories(id) on delete set null,
  is_archived   boolean not null default false,
  display_order int not null default 0,
  created_at    timestamptz not null default now()
);

create index idx_categories_household on public.categories(household_id);
create index idx_categories_parent    on public.categories(parent_id);

-- ------------------------------------------------------------
-- transactions
--   Poznámka: FK na recurring_templates pridávame až po jeho
--   vytvorení nižšie, aby sa dalo vytvoriť v jednom súbore.
-- ------------------------------------------------------------
create table public.transactions (
  id                      uuid primary key default gen_random_uuid(),
  household_id            uuid not null references public.households(id) on delete cascade,
  account_id              uuid not null references public.accounts(id) on delete restrict,
  category_id             uuid references public.categories(id) on delete set null,
  type                    text not null check (type in ('income','expense','transfer')),
  amount                  numeric(14,2) not null check (amount > 0),
  currency                text not null default 'EUR',
  date                    date not null,
  description             text,
  note                    text,
  transfer_to_account_id  uuid references public.accounts(id) on delete restrict,
  recurring_template_id   uuid,
  created_by              uuid references auth.users(id) on delete set null,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index idx_transactions_household_date on public.transactions(household_id, date desc);
create index idx_transactions_account        on public.transactions(account_id);
create index idx_transactions_category       on public.transactions(category_id);

create trigger trg_transactions_updated_at
  before update on public.transactions
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- recurring_templates
-- ------------------------------------------------------------
create table public.recurring_templates (
  id               uuid primary key default gen_random_uuid(),
  household_id     uuid not null references public.households(id) on delete cascade,
  account_id       uuid not null references public.accounts(id) on delete restrict,
  category_id      uuid references public.categories(id) on delete set null,
  type             text not null check (type in ('income','expense','transfer')),
  amount           numeric(14,2) not null check (amount > 0),
  currency         text not null default 'EUR',
  description      text,
  frequency        text not null check (frequency in ('daily','weekly','monthly','yearly')),
  interval_count   int  not null default 1 check (interval_count >= 1),
  start_date       date not null,
  end_date         date,
  next_occurrence  date,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now()
);

create index idx_recurring_household on public.recurring_templates(household_id);

-- Dokončenie FK pre transactions.recurring_template_id
alter table public.transactions
  add constraint fk_transactions_recurring_template
  foreign key (recurring_template_id)
  references public.recurring_templates(id)
  on delete set null;

-- ------------------------------------------------------------
-- budgets
-- ------------------------------------------------------------
create table public.budgets (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references public.households(id) on delete cascade,
  category_id   uuid not null references public.categories(id) on delete cascade,
  amount        numeric(14,2) not null check (amount > 0),
  period        text not null check (period in ('monthly','yearly')),
  start_date    date not null,
  end_date      date,
  created_at    timestamptz not null default now(),
  unique (household_id, category_id, period, start_date)
);

create index idx_budgets_household on public.budgets(household_id);
