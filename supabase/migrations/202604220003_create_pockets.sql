create extension if not exists pgcrypto;

create table if not exists public.pockets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  emoji text not null default '🎯',
  goal_amount numeric(12,2) not null check (goal_amount > 0),
  saved_amount numeric(12,2) not null default 0 check (saved_amount >= 0),
  color text not null default '#5F4A8B',
  is_completed boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists pockets_tenant_id_idx on public.pockets(tenant_id);

alter table public.pockets enable row level security;

drop policy if exists "Users can manage their own pockets" on public.pockets;
create policy "Users can manage their own pockets"
on public.pockets for all
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
