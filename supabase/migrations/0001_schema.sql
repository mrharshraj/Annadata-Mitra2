-- Phase 2 migration 0001: core schema for Annadata Mitra (spec revision).
-- Hierarchy: state → district → block → panchayat → village → profile → field.
-- Conventions: UUID PKs (gen_random_uuid), timestamptz audit columns,
-- RESTRICT on reference FKs, CASCADE on farmer-owned rows.
-- NOTE: committed but never applied to any database; reconciled to the
-- Phase 2 column contract before first push (no live data to migrate).

create extension if not exists "pgcrypto";

-- Auto-maintain updated_at on every row change.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------- states
create table public.states (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger states_touch
  before update on public.states
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------- districts
create table public.districts (
  id uuid primary key default gen_random_uuid(),
  state_id uuid not null references public.states (id) on delete restrict,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (state_id, name)
);
create index districts_state_id_idx on public.districts (state_id);
create trigger districts_touch
  before update on public.districts
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------- blocks
create table public.blocks (
  id uuid primary key default gen_random_uuid(),
  district_id uuid not null references public.districts (id) on delete restrict,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (district_id, name)
);
create index blocks_district_id_idx on public.blocks (district_id);
create trigger blocks_touch
  before update on public.blocks
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------ panchayats
create table public.panchayats (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null references public.blocks (id) on delete restrict,
  name text not null,
  code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (block_id, name)
);
create index panchayats_block_id_idx on public.panchayats (block_id);
create trigger panchayats_touch
  before update on public.panchayats
  for each row execute function public.touch_updated_at();

-- -------------------------------------------------------------- villages
create table public.villages (
  id uuid primary key default gen_random_uuid(),
  panchayat_id uuid not null references public.panchayats (id) on delete restrict,
  name text not null,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (panchayat_id, name)
);
create index villages_panchayat_id_idx on public.villages (panchayat_id);
create trigger villages_touch
  before update on public.villages
  for each row execute function public.touch_updated_at();

-- --------------------------------------------------------------- profiles
-- One row per Supabase Auth user; id IS the auth.users id.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  phone text,
  preferred_language text not null default 'hi'
    check (preferred_language in ('en', 'hi')),
  state_id uuid references public.states (id) on delete set null,
  district_id uuid references public.districts (id) on delete set null,
  block_id uuid references public.blocks (id) on delete set null,
  panchayat_id uuid references public.panchayats (id) on delete set null,
  village_id uuid references public.villages (id) on delete set null,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index profiles_village_id_idx on public.profiles (village_id);
create index profiles_phone_idx on public.profiles (phone);
create trigger profiles_touch
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------------------- fields
create table public.fields (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  village_id uuid references public.villages (id) on delete set null,
  name text not null,
  area_value numeric check (area_value is null or area_value > 0),
  area_unit text not null default 'acre'
    check (area_unit in ('acre', 'hectare', 'bigha', 'gunta')),
  latitude double precision,
  longitude double precision,
  soil_type text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index fields_profile_id_idx on public.fields (profile_id);
create index fields_village_id_idx on public.fields (village_id);
create trigger fields_touch
  before update on public.fields
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------------ crops
-- Shared reference catalog (read-only for farmers).
create table public.crops (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  scientific_name text,
  category text,
  season text,
  description text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------ field_crops
create table public.field_crops (
  id uuid primary key default gen_random_uuid(),
  field_id uuid not null references public.fields (id) on delete cascade,
  crop_id uuid not null references public.crops (id) on delete restrict,
  sowing_date date,
  expected_harvest_date date,
  status text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    expected_harvest_date is null
    or sowing_date is null
    or expected_harvest_date >= sowing_date
  )
);
create index field_crops_field_id_idx on public.field_crops (field_id);
create index field_crops_crop_id_idx on public.field_crops (crop_id);
create trigger field_crops_touch
  before update on public.field_crops
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------------ tasks
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  field_id uuid references public.fields (id) on delete set null,
  crop_id uuid references public.crops (id) on delete set null,
  title text not null check (char_length(title) between 1 and 200),
  description text,
  due_date timestamptz,
  priority text not null default 'medium'
    check (priority in ('low', 'medium', 'high')),
  status text not null default 'pending'
    check (status in ('pending', 'in_progress', 'done', 'cancelled')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index tasks_profile_id_idx on public.tasks (profile_id);
create index tasks_due_date_idx on public.tasks (due_date)
  where status <> 'done';
create trigger tasks_touch
  before update on public.tasks
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------- weather_advisories
-- Written by the backend service role (Phase 8); farmers read rows for
-- their own village (or rows assigned to their profile).
create table public.weather_advisories (
  id uuid primary key default gen_random_uuid(),
  village_id uuid not null references public.villages (id) on delete cascade,
  profile_id uuid references public.profiles (id) on delete cascade,
  weather_date date not null,
  temperature numeric,
  rainfall numeric,
  humidity numeric,
  wind numeric,
  advisory_text text,
  severity text not null default 'info'
    check (severity in ('info', 'watch', 'warning')),
  created_at timestamptz not null default now(),
  unique (village_id, weather_date)
);
create index weather_advisories_village_id_idx
  on public.weather_advisories (village_id);
create index weather_advisories_profile_id_idx
  on public.weather_advisories (profile_id);

-- ------------------------------------------------------------ crop_advice
-- Shared agronomy reference (read-only for farmers); field_id/profile_id
-- allow targeting a note at one farm without making it private data.
create table public.crop_advice (
  id uuid primary key default gen_random_uuid(),
  crop_id uuid not null references public.crops (id) on delete cascade,
  field_id uuid references public.fields (id) on delete cascade,
  profile_id uuid references public.profiles (id) on delete cascade,
  advice_type text,
  title text not null,
  content text not null,
  severity text not null default 'info'
    check (severity in ('info', 'watch', 'warning')),
  created_at timestamptz not null default now()
);
create index crop_advice_crop_id_idx on public.crop_advice (crop_id);

-- -------------------------------------------------------- ai_conversations
create table public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  title text,
  language text not null default 'hi'
    check (language in ('en', 'hi')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index ai_conversations_profile_id_idx
  on public.ai_conversations (profile_id);
create trigger ai_conversations_touch
  before update on public.ai_conversations
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------- ai_messages
create table public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations (id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  metadata jsonb,
  created_at timestamptz not null default now()
);
create index ai_messages_conversation_id_idx
  on public.ai_messages (conversation_id);

-- -------------------------------------------------------------- crop_scans
-- Image bytes live in the private `crop-scans` Storage bucket; only the
-- object path + analysis live here.
create table public.crop_scans (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  field_id uuid references public.fields (id) on delete set null,
  image_path text not null,
  detected_crop text,
  detected_issue text,
  confidence numeric
    check (confidence is null or (confidence >= 0 and confidence <= 1)),
  analysis jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'done', 'failed')),
  created_at timestamptz not null default now()
);
create index crop_scans_profile_id_idx on public.crop_scans (profile_id);
