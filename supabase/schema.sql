create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('customer', 'worker')),
  full_name text not null,
  email text,
  phone text not null,
  city text not null,
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.worker_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  service_category text not null,
  years_experience integer not null default 0,
  national_id text not null,
  hourly_rate numeric(10, 2) not null default 0,
  bio text not null,
  is_available boolean not null default true,
  rating numeric(3, 2) not null default 4.7,
  completed_jobs integer not null default 0,
  is_verified boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    role,
    full_name,
    email,
    phone,
    city
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'role', 'customer'),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'city', '')
  )
  on conflict (id) do update
  set
    role = excluded.role,
    full_name = excluded.full_name,
    email = excluded.email,
    phone = excluded.phone,
    city = excluded.city;

  if coalesce(new.raw_user_meta_data->>'role', 'customer') = 'worker' then
    insert into public.worker_profiles (
      id,
      service_category,
      years_experience,
      national_id,
      hourly_rate,
      bio,
      is_available
    )
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'service_category', 'Plumbing'),
      coalesce((new.raw_user_meta_data->>'years_experience')::integer, 0),
      coalesce(new.raw_user_meta_data->>'national_id', ''),
      coalesce((new.raw_user_meta_data->>'hourly_rate')::numeric, 0),
      coalesce(new.raw_user_meta_data->>'bio', ''),
      true
    )
    on conflict (id) do update
    set
      service_category = excluded.service_category,
      years_experience = excluded.years_experience,
      national_id = excluded.national_id,
      hourly_rate = excluded.hourly_rate,
      bio = excluded.bio;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid references public.profiles(id) on delete set null,
  customer_name text not null,
  worker_name text,
  category text not null,
  title text not null,
  description text not null,
  address text not null,
  scheduled_for timestamptz not null,
  price numeric(10, 2) not null default 0,
  status text not null default 'pending' check (
    status in ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')
  ),
  thread_id uuid,
  attachment_url text,
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.service_requests
  add column if not exists completed_at timestamptz;

create table if not exists public.message_threads (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.service_requests(id) on delete cascade,
  customer_name text not null,
  worker_name text not null default 'FixIt Dispatch',
  last_message text not null default '',
  last_message_at timestamptz not null default timezone('utc', now()),
  unread_count integer not null default 0,
  is_online boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'service_requests_thread_id_fkey'
      and conrelid = 'public.service_requests'::regclass
  ) then
    alter table public.service_requests
      add constraint service_requests_thread_id_fkey
      foreign key (thread_id) references public.message_threads(id) on delete set null;
  end if;
end $$;

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.message_threads(id) on delete cascade,
  sender_id uuid references public.profiles(id) on delete set null,
  receiver_id uuid references public.profiles(id) on delete set null,
  body text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('request', 'message', 'earning', 'system')),
  is_read boolean not null default false,
  request_id uuid references public.service_requests(id) on delete set null,
  thread_id uuid references public.message_threads(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('customer', 'worker')),
  type text not null check (type in ('bug', 'support')),
  subject text not null,
  message text not null,
  status text not null default 'open' check (
    status in ('open', 'in_review', 'resolved', 'closed')
  ),
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_service_requests_customer_id
  on public.service_requests(customer_id);

create index if not exists idx_service_requests_worker_id
  on public.service_requests(worker_id);

create index if not exists idx_service_requests_status
  on public.service_requests(status);

create index if not exists idx_message_threads_request_id
  on public.message_threads(request_id);

create index if not exists idx_messages_thread_id
  on public.messages(thread_id);

create index if not exists idx_notifications_user_id
  on public.notifications(user_id);

create index if not exists idx_support_tickets_user_id
  on public.support_tickets(user_id);

alter table public.profiles enable row level security;
alter table public.worker_profiles enable row level security;
alter table public.service_requests enable row level security;
alter table public.message_threads enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.support_tickets enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "profiles_select_workers_directory" on public.profiles;
create policy "profiles_select_workers_directory"
on public.profiles
for select
to authenticated
using (
  role = 'worker'
  and exists (
    select 1
    from public.worker_profiles
    where worker_profiles.id = profiles.id
      and worker_profiles.is_available = true
  )
);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "worker_profiles_select_directory" on public.worker_profiles;
create policy "worker_profiles_select_directory"
on public.worker_profiles
for select
to authenticated
using (is_available = true or auth.uid() = id);

drop policy if exists "worker_profiles_insert_own" on public.worker_profiles;
create policy "worker_profiles_insert_own"
on public.worker_profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "worker_profiles_update_own" on public.worker_profiles;
create policy "worker_profiles_update_own"
on public.worker_profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "requests_visible_to_customer_or_worker" on public.service_requests;
create policy "requests_visible_to_customer_or_worker"
on public.service_requests
for select
to authenticated
using (
  auth.uid() = customer_id
  or auth.uid() = worker_id
  or (
    status = 'pending'
    and exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'worker'
    )
    and (worker_id is null or worker_id = auth.uid())
  )
);

drop policy if exists "customers_insert_requests" on public.service_requests;
create policy "customers_insert_requests"
on public.service_requests
for insert
to authenticated
with check (
  auth.uid() = customer_id
  and exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role = 'customer'
  )
);

drop policy if exists "workers_or_customer_update_requests" on public.service_requests;
create policy "workers_or_customer_update_requests"
on public.service_requests
for update
to authenticated
using (
  auth.uid() = customer_id
  or auth.uid() = worker_id
  or (
    status = 'pending'
    and exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'worker'
    )
    and (worker_id is null or worker_id = auth.uid())
  )
)
with check (
  auth.uid() = customer_id
  or auth.uid() = worker_id
  or (
    exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'worker'
    )
    and (worker_id is null or worker_id = auth.uid())
  )
);

drop policy if exists "threads_visible_to_request_participants" on public.message_threads;
create policy "threads_visible_to_request_participants"
on public.message_threads
for select
to authenticated
using (
  exists (
    select 1
    from public.service_requests
    where service_requests.id = message_threads.request_id
      and (
        service_requests.customer_id = auth.uid()
        or service_requests.worker_id = auth.uid()
        or (
          service_requests.status = 'pending'
          and exists (
            select 1
            from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'worker'
          )
          and (
            service_requests.worker_id is null
            or service_requests.worker_id = auth.uid()
          )
        )
      )
  )
);

drop policy if exists "threads_insert_for_request_owner" on public.message_threads;
create policy "threads_insert_for_request_owner"
on public.message_threads
for insert
to authenticated
with check (
  exists (
    select 1
    from public.service_requests
    where service_requests.id = request_id
      and service_requests.customer_id = auth.uid()
  )
);

drop policy if exists "threads_update_for_participants" on public.message_threads;
create policy "threads_update_for_participants"
on public.message_threads
for update
to authenticated
using (
  exists (
    select 1
    from public.service_requests
    where service_requests.id = message_threads.request_id
      and (
        service_requests.customer_id = auth.uid()
        or service_requests.worker_id = auth.uid()
        or (
          service_requests.status = 'pending'
          and exists (
            select 1
            from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'worker'
          )
          and (
            service_requests.worker_id is null
            or service_requests.worker_id = auth.uid()
          )
        )
      )
  )
)
with check (
  exists (
    select 1
    from public.service_requests
    where service_requests.id = request_id
      and (
        service_requests.customer_id = auth.uid()
        or service_requests.worker_id = auth.uid()
        or (
          service_requests.status = 'pending'
          and exists (
            select 1
            from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'worker'
          )
          and (
            service_requests.worker_id is null
            or service_requests.worker_id = auth.uid()
          )
        )
      )
  )
);

drop policy if exists "messages_visible_to_thread_participants" on public.messages;
create policy "messages_visible_to_thread_participants"
on public.messages
for select
to authenticated
using (
  sender_id = auth.uid()
  or receiver_id = auth.uid()
  or exists (
    select 1
    from public.message_threads
    join public.service_requests
      on service_requests.id = message_threads.request_id
    where message_threads.id = messages.thread_id
      and (
        service_requests.customer_id = auth.uid()
        or service_requests.worker_id = auth.uid()
        or (
          service_requests.status = 'pending'
          and exists (
            select 1
            from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'worker'
          )
          and (
            service_requests.worker_id is null
            or service_requests.worker_id = auth.uid()
          )
        )
      )
  )
);

drop policy if exists "messages_insert_for_thread_participants" on public.messages;
create policy "messages_insert_for_thread_participants"
on public.messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.message_threads
    join public.service_requests
      on service_requests.id = message_threads.request_id
    where message_threads.id = thread_id
      and (
        service_requests.customer_id = auth.uid()
        or service_requests.worker_id = auth.uid()
        or (
          service_requests.status = 'pending'
          and exists (
            select 1
            from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'worker'
          )
          and (
            service_requests.worker_id is null
            or service_requests.worker_id = auth.uid()
          )
        )
      )
  )
);

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "notifications_insert_participants" on public.notifications;
create policy "notifications_insert_participants"
on public.notifications
for insert
to authenticated
with check (true);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "support_tickets_select_own" on public.support_tickets;
create policy "support_tickets_select_own"
on public.support_tickets
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "support_tickets_insert_own" on public.support_tickets;
create policy "support_tickets_insert_own"
on public.support_tickets
for insert
to authenticated
with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('request-images', 'request-images', true)
on conflict (id) do nothing;

drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
on storage.objects
for select
to public
using (bucket_id = 'avatars');

drop policy if exists "avatars_authenticated_upload" on storage.objects;
create policy "avatars_authenticated_upload"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'avatars');

drop policy if exists "avatars_authenticated_update" on storage.objects;
create policy "avatars_authenticated_update"
on storage.objects
for update
to authenticated
using (bucket_id = 'avatars')
with check (bucket_id = 'avatars');

drop policy if exists "request_images_public_read" on storage.objects;
create policy "request_images_public_read"
on storage.objects
for select
to public
using (bucket_id = 'request-images');

drop policy if exists "request_images_authenticated_upload" on storage.objects;
create policy "request_images_authenticated_upload"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'request-images');

drop policy if exists "request_images_authenticated_update" on storage.objects;
create policy "request_images_authenticated_update"
on storage.objects
for update
to authenticated
using (bucket_id = 'request-images')
with check (bucket_id = 'request-images');
