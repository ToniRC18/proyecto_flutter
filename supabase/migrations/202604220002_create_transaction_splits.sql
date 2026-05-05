create extension if not exists pgcrypto;

alter table public.transactions
  add column if not exists has_split boolean not null default false;

create table if not exists public.transaction_splits (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  amount numeric(12, 2) not null,
  is_settled boolean not null default false,
  settled_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists transaction_splits_transaction_id_idx
  on public.transaction_splits (transaction_id);
create index if not exists transaction_splits_user_id_idx
  on public.transaction_splits (user_id);
create index if not exists transaction_splits_settled_idx
  on public.transaction_splits (is_settled);

alter table public.transaction_splits enable row level security;

drop policy if exists "Members can view splits of their spaces" on public.transaction_splits;
create policy "Members can view splits of their spaces"
on public.transaction_splits
for all
using (
  transaction_id in (
    select t.id
    from public.transactions t
    join public.tenant_members tm on tm.tenant_id = t.tenant_id
    where tm.user_id = auth.uid()
  )
)
with check (
  transaction_id in (
    select t.id
    from public.transactions t
    join public.tenant_members tm on tm.tenant_id = t.tenant_id
    where tm.user_id = auth.uid()
  )
);
