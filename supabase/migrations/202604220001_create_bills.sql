create extension if not exists pgcrypto;

create table if not exists public.bills (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  amount numeric(12, 2) not null,
  due_day integer not null check (due_day >= 1 and due_day <= 31),
  frequency text not null check (frequency in ('monthly', 'weekly', 'yearly')),
  category text not null default 'bills',
  account_id uuid references public.accounts(id) on delete set null,
  is_active boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists bills_tenant_id_idx on public.bills (tenant_id);
create index if not exists bills_account_id_idx on public.bills (account_id);
create index if not exists bills_active_due_day_idx
  on public.bills (tenant_id, is_active, due_day);

alter table public.bills enable row level security;

drop policy if exists "Users can manage their own bills" on public.bills;
create policy "Users can manage their own bills"
on public.bills
for all
using (
  tenant_id in (
    select tenant_id
    from public.tenant_members
    where user_id = auth.uid()
  )
)
with check (
  tenant_id in (
    select tenant_id
    from public.tenant_members
    where user_id = auth.uid()
  )
);

create table if not exists public.bill_payments (
  id uuid primary key default gen_random_uuid(),
  bill_id uuid not null references public.bills(id) on delete cascade,
  paid_at timestamptz not null default now(),
  amount numeric(12, 2) not null,
  transaction_id uuid references public.transactions(id) on delete set null
);

create index if not exists bill_payments_bill_id_idx
  on public.bill_payments (bill_id);
create index if not exists bill_payments_transaction_id_idx
  on public.bill_payments (transaction_id);
create index if not exists bill_payments_paid_at_idx
  on public.bill_payments (paid_at desc);

alter table public.bill_payments enable row level security;

drop policy if exists "Users can manage their own bill_payments" on public.bill_payments;
create policy "Users can manage their own bill_payments"
on public.bill_payments
for all
using (
  bill_id in (
    select b.id
    from public.bills b
    where b.tenant_id in (
      select tenant_id
      from public.tenant_members
      where user_id = auth.uid()
    )
  )
)
with check (
  bill_id in (
    select b.id
    from public.bills b
    where b.tenant_id in (
      select tenant_id
      from public.tenant_members
      where user_id = auth.uid()
    )
  )
);
