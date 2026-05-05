-- Extensiones necesarias para invocar Edge Functions y programar recordatorios.
create extension if not exists pg_net;
create extension if not exists pg_cron;

-- Helpers para construir la URL de Supabase y el bearer de service role.
-- Si tu proyecto no expone estos settings, reemplaza los valores fallback.
create or replace function public.get_supabase_project_url()
returns text
language plpgsql
as $$
declare
  v_url text;
begin
  v_url := current_setting('app.settings.supabase_url', true);
  if v_url is null or v_url = '' then
    v_url := current_setting('app.supabase_url', true);
  end if;
  if v_url is null or v_url = '' then
    -- TODO: reemplazar solo si tu proyecto no expone app.settings.supabase_url.
    v_url := 'https://uzttgvjntpusacoiowyn.supabase.co';
  end if;
  return v_url;
end;
$$;

create or replace function public.get_service_role_bearer()
returns text
language plpgsql
as $$
declare
  v_key text;
begin
  v_key := current_setting('app.settings.service_role_key', true);
  if v_key is null or v_key = '' then
    v_key := current_setting('app.service_role_key', true);
  end if;
  if v_key is null or v_key = '' then
    -- TODO: reemplazar por la service_role_key real si no está disponible en settings.
    v_key := 'REPLACE_WITH_SERVICE_ROLE_KEY';
  end if;
  return 'Bearer ' || v_key;
end;
$$;

create or replace function public.push_function_url()
returns text
language sql
as $$
  select public.get_supabase_project_url() || '/functions/v1/send-push-notification';
$$;

-- Trigger 1: notifica cuando se crea una invitación a espacio compartido.
create or replace function public.notify_shared_space_invitation()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid;
begin
  select u.id
  into v_user_id
  from auth.users u
  where lower(u.email) = lower(new.invited_email)
  limit 1;

  if v_user_id is null then
    return new;
  end if;

  perform net.http_post(
    url := public.push_function_url(),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', public.get_service_role_bearer()
    ),
    body := jsonb_build_object(
      'user_id', v_user_id::text,
      'title', 'Nueva invitación 👥',
      'body', 'Te invitaron a unirse a un espacio compartido en bruma.',
      'data', jsonb_build_object(
        'type', 'invitation',
        'invitation_id', new.id::text
      )
    )
  );

  return new;
exception
  when others then
    raise warning 'notify_shared_space_invitation falló para %: %', new.id, sqlerrm;
    return new;
end;
$$;

drop trigger if exists tenant_invitations_push_notification on public.tenant_invitations;
create trigger tenant_invitations_push_notification
after insert on public.tenant_invitations
for each row execute function public.notify_shared_space_invitation();

-- Trigger 2: notifica al miembro al que le registraron un split.
-- Nota: el esquema actual no expone created_by en transactions ni owner de accounts.
-- Con las columnas reales disponibles, solo se evita la notificación si el tenant
-- no tiene más miembros además del deudor.
create or replace function public.notify_transaction_split_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_has_other_members boolean;
begin
  select t.tenant_id
  into v_tenant_id
  from public.transactions t
  where t.id = new.transaction_id;

  if v_tenant_id is null then
    return new;
  end if;

  select exists (
    select 1
    from public.tenant_members tm
    where tm.tenant_id = v_tenant_id
      and tm.user_id <> new.user_id
  )
  into v_has_other_members;

  if not coalesce(v_has_other_members, false) then
    return new;
  end if;

  perform net.http_post(
    url := public.push_function_url(),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', public.get_service_role_bearer()
    ),
    body := jsonb_build_object(
      'user_id', new.user_id::text,
      'title', 'Gasto compartido registrado 💸',
      'body', 'Te registraron un gasto de $' || trim(to_char(new.amount, 'FM999999990.00')) || ' en un espacio compartido.',
      'data', jsonb_build_object(
        'type', 'split',
        'transaction_id', new.transaction_id::text,
        'amount', new.amount::text
      )
    )
  );

  return new;
exception
  when others then
    raise warning 'notify_transaction_split_created falló para %: %', new.id, sqlerrm;
    return new;
end;
$$;

drop trigger if exists transaction_splits_push_created on public.transaction_splits;
create trigger transaction_splits_push_created
after insert on public.transaction_splits
for each row execute function public.notify_transaction_split_created();

-- Trigger 4: notifica al resto del tenant cuando una deuda quedó saldada.
create or replace function public.notify_transaction_split_settled()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
begin
  if new.is_settled is distinct from true or old.is_settled is true then
    return new;
  end if;

  select t.tenant_id
  into v_tenant_id
  from public.transactions t
  where t.id = new.transaction_id;

  if v_tenant_id is null then
    return new;
  end if;

  perform net.http_post(
    url := public.push_function_url(),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', public.get_service_role_bearer()
    ),
    body := jsonb_build_object(
      'user_id', tm.user_id::text,
      'title', '¡Deuda saldada! ✅',
      'body', 'Alguien saldó una deuda contigo en bruma.',
      'data', jsonb_build_object(
        'type', 'settlement',
        'transaction_id', new.transaction_id::text
      )
    )
  )
  from public.tenant_members tm
  where tm.tenant_id = v_tenant_id
    and tm.user_id <> new.user_id;

  return new;
exception
  when others then
    raise warning 'notify_transaction_split_settled falló para %: %', new.id, sqlerrm;
    return new;
end;
$$;

drop trigger if exists transaction_splits_push_settled on public.transaction_splits;
create trigger transaction_splits_push_settled
after update on public.transaction_splits
for each row
when (new.is_settled = true and old.is_settled = false)
execute function public.notify_transaction_split_settled();

-- Trigger 3: recordatorios diarios de bills próximas a vencer.
-- Si ya existe el job, se elimina antes de recrearlo para evitar duplicados.
do $$
declare
  v_job_id bigint;
begin
  select jobid
  into v_job_id
  from cron.job
  where jobname = 'bill-reminders'
  limit 1;

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;

  perform cron.schedule(
    'bill-reminders',
    '0 9 * * *',
    $cron$
      select net.http_post(
        url := public.push_function_url(),
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', public.get_service_role_bearer()
        ),
        body := jsonb_build_object(
          'user_id', tm.user_id::text,
          'title', '📅 Pago próximo',
          'body', 'Tu pago de ' || b.name || ' vence mañana.',
          'data', jsonb_build_object(
            'type', 'bill_reminder',
            'bill_id', b.id::text
          )
        )
      )
      from public.bills b
      join public.tenant_members tm on tm.tenant_id = b.tenant_id
      where b.is_active = true
        and b.due_day = extract(day from (current_date + interval '1 day'));
    $cron$
  );
end;
$$;
