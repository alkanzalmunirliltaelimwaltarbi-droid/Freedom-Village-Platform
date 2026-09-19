-- منصة قرية الحرية — Supabase schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  email text not null default '',
  is_admin boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.content_items (
  id text primary key,
  category text not null check (category in ('news','services','emergency','events','directory')),
  title text not null default '',
  body text not null default '',
  date text,
  extra jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.requests (
  id text primary key,
  tracking text unique not null,
  type text not null check (type in ('complaint','suggestion')),
  name text not null default '',
  phone text not null default '',
  body text not null default '',
  status text not null default 'under_review',
  status_label text not null default 'قيد المراجعة',
  user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.prayer_times (
  id integer primary key default 1 check (id=1),
  fajr text default '', sunrise text default '', dhuhr text default '', asr text default '', maghrib text default '', isha text default '',
  image_url text
);

create table if not exists public.app_settings (
  id integer primary key default 1 check (id=1),
  village text not null default 'قرية الحرية',
  description text not null default 'منصة خدمية مركزية للأخبار والخدمات والمعلومات والشكاوى والاقتراحات.',
  hijri_offset integer not null default 0,
  logo_url text
);

insert into public.prayer_times(id) values(1) on conflict do nothing;
insert into public.app_settings(id) values(1) on conflict do nothing;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_admin=true and p.active=true); $$;

alter table public.profiles enable row level security;
alter table public.content_items enable row level security;
alter table public.requests enable row level security;
alter table public.prayer_times enable row level security;
alter table public.app_settings enable row level security;

drop policy if exists profiles_select on public.profiles;
drop policy if exists profiles_insert on public.profiles;
drop policy if exists profiles_update on public.profiles;
drop policy if exists profiles_delete on public.profiles;
create policy profiles_select on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy profiles_insert on public.profiles for insert to authenticated with check (id=auth.uid() or public.is_admin());
create policy profiles_update on public.profiles for update to authenticated using (id=auth.uid() or public.is_admin()) with check ((id=auth.uid() and is_admin=(select p.is_admin from public.profiles p where p.id=auth.uid())) or public.is_admin());
create policy profiles_delete on public.profiles for delete to authenticated using (public.is_admin());

drop policy if exists content_select on public.content_items;
drop policy if exists content_admin_insert on public.content_items;
drop policy if exists content_admin_update on public.content_items;
drop policy if exists content_admin_delete on public.content_items;
create policy content_select on public.content_items for select to authenticated using (true);
create policy content_admin_insert on public.content_items for insert to authenticated with check (public.is_admin());
create policy content_admin_update on public.content_items for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy content_admin_delete on public.content_items for delete to authenticated using (public.is_admin());

drop policy if exists requests_select on public.requests;
drop policy if exists requests_insert on public.requests;
drop policy if exists requests_update on public.requests;
drop policy if exists requests_delete on public.requests;
create policy requests_select on public.requests for select to authenticated using (user_id=auth.uid() or public.is_admin());
create policy requests_insert on public.requests for insert to authenticated with check (user_id=auth.uid());
create policy requests_update on public.requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy requests_delete on public.requests for delete to authenticated using (public.is_admin());

drop policy if exists prayer_select on public.prayer_times;
drop policy if exists prayer_admin_write on public.prayer_times;
create policy prayer_select on public.prayer_times for select to authenticated using (true);
create policy prayer_admin_write on public.prayer_times for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists settings_select on public.app_settings;
drop policy if exists settings_admin_write on public.app_settings;
create policy settings_select on public.app_settings for select to authenticated using (true);
create policy settings_admin_write on public.app_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Storage bucket. Create this bucket in Storage if it does not exist.
insert into storage.buckets (id,name,public) values ('public-assets','public-assets',true) on conflict (id) do update set public=true;

drop policy if exists assets_public_read on storage.objects;
drop policy if exists assets_admin_insert on storage.objects;
drop policy if exists assets_admin_update on storage.objects;
drop policy if exists assets_admin_delete on storage.objects;
create policy assets_public_read on storage.objects for select using (bucket_id='public-assets');
create policy assets_admin_insert on storage.objects for insert to authenticated with check (bucket_id='public-assets' and public.is_admin());
create policy assets_admin_update on storage.objects for update to authenticated using (bucket_id='public-assets' and public.is_admin()) with check (bucket_id='public-assets' and public.is_admin());
create policy assets_admin_delete on storage.objects for delete to authenticated using (bucket_id='public-assets' and public.is_admin());
