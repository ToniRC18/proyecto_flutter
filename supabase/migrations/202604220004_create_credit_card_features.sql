-- Columnas extra en accounts para tarjetas de crédito
-- Solo aplican cuando type = 'credit_card', el resto son NULL
alter table public.accounts
  add column if not exists credit_limit      numeric(12,2),
  add column if not exists billing_close_day integer check (billing_close_day between 1 and 31),
  add column if not exists payment_due_day   integer check (payment_due_day between 1 and 31);

-- Compras a meses sin intereses
create table if not exists public.msi_plans (
  id           uuid primary key default gen_random_uuid(),
  account_id   uuid not null references public.accounts(id) on delete cascade,
  tenant_id    uuid not null references public.tenants(id) on delete cascade,
  store_name   text not null,
  total_amount numeric(12,2) not null check (total_amount > 0),
  months_total integer not null check (months_total > 1),
  months_paid  integer not null default 0 check (months_paid >= 0),
  start_date   date not null,
  is_active    boolean not null default true,
  notes        text,
  created_at   timestamptz not null default now()
);

create index if not exists msi_plans_account_id_idx on public.msi_plans(account_id);
create index if not exists msi_plans_tenant_id_idx  on public.msi_plans(tenant_id);

alter table public.msi_plans enable row level security;

create policy "Users can manage their own msi_plans"
on public.msi_plans for all
using (
  tenant_id in (
    select tenant_id from public.tenant_members where user_id = auth.uid()
  )
)
with check (
  tenant_id in (
    select tenant_id from public.tenant_members where user_id = auth.uid()
  )
);
