-- Phase 2 migration 0001: core schema for Annadata Mitra.
-- Hierarchy: state → district → block → panchayat → village → farmer → field → crop.
-- Conventions: UUID PKs (gen_random_uuid), timestamptz audit columns,
-- FKs with RESTRICT on reference data and CASCADE on farmer-owned rows.

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

-- ------------------------------------------------------- farmer_profiles
-- One row per Supabase Auth user; id IS the auth.users id.
create table public.farmer_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  village_id uuid references public.villages (id) on delete set null,
  name text not null,
  phone text,
  preferred_language text not null default 'hi'
    check (preferred_language in ('en', 'hi')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index farmer_profiles_village_id_idx on public.farmer_profiles (village_id);
create trigger farmer_profiles_touch
  before update on public.farmer_profiles
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------------------- fields
create table public.fields (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.farmer_profiles (id) on delete cascade,
  name text not null,
  area_acres numeric check (area_acres is null or area_acres > 0),
  latitude double precision,
  longitude double precision,
  soil_type text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index fields_farmer_id_idx on public.fields (farmer_id);
create trigger fields_touch
  before update on public.fields
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------------ crops
-- Shared reference catalog (read-only for farmers).
create table public.crops (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  crop_type text,
  season text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger crops_touch
  before update on public.crops
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------ field_crops
create table public.field_crops (
  id uuid primary key default gen_random_uuid(),
  field_id uuid not null references public.fields (id) on delete cascade,
  crop_id uuid not null references public.crops (id) on delete restrict,
  sowing_date date,
  expected_harvest date,
  status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (expected_harvest is null or sowing_date is null or expected_harvest >= sowing_date)
);
create index field_crops_field_id_idx on public.field_crops (field_id);
create index field_crops_crop_id_idx on public.field_crops (crop_id);
create trigger field_crops_touch
  before update on public.field_crops
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------- todo_tasks
create table public.todo_tasks (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.farmer_profiles (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  description text,
  due_date timestamptz,
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index todo_tasks_farmer_id_idx on public.todo_tasks (farmer_id);
create index todo_tasks_due_date_idx on public.todo_tasks (due_date)
  where is_completed = false;
create trigger todo_tasks_touch
  before update on public.todo_tasks
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------- weather_advisories
-- Written by the backend service role (Phase 8); farmers read their own
-- village rows.
create table public.weather_advisories (
  id uuid primary key default gen_random_uuid(),
  village_id uuid not null references public.villages (id) on delete cascade,
  advisory_date date not null,
  weather_data jsonb,
  advisory_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (village_id, advisory_date)
);
create index weather_advisories_village_id_idx on public.weather_advisories (village_id);
create trigger weather_advisories_touch
  before update on public.weather_advisories
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------ crop_advice
-- Shared agronomy reference (read-only for farmers).
create table public.crop_advice (
  id uuid primary key default gen_random_uuid(),
  crop_id uuid not null references public.crops (id) on delete cascade,
  title text not null,
  advice_text text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index crop_advice_crop_id_idx on public.crop_advice (crop_id);
create trigger crop_advice_touch
  before update on public.crop_advice
  for each row execute function public.touch_updated_at();

-- -------------------------------------------------------- ai_conversations
create table public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.farmer_profiles (id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index ai_conversations_farmer_id_idx on public.ai_conversations (farmer_id);
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
create index ai_messages_conversation_id_idx on public.ai_messages (conversation_id);

-- -------------------------------------------------------------- crop_scans
-- Image bytes live in the private `crop-scans` Storage bucket; only the
-- object path + analysis live here.
create table public.crop_scans (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.farmer_profiles (id) on delete cascade,
  field_id uuid references public.fields (id) on delete set null,
  image_path text not null,
  detected_crop text,
  detected_issue text,
  confidence numeric check (confidence is null or (confidence >= 0 and confidence <= 1)),
  analysis jsonb,
  created_at timestamptz not null default now()
);
create index crop_scans_farmer_id_idx on public.crop_scans (farmer_id);
