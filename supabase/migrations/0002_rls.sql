-- Phase 2 migration 0002: Row Level Security.
-- Farmers access ONLY their own private rows. Reference catalogs
-- (locations, crops, crop_advice) are readable by any authenticated user
-- and writable only via service role / later admin (no write policy here).
-- Weather advisories are written by the backend service role (Phase 8);
-- farmers read rows for their own village.

-- Ownership helpers -------------------------------------------------------
create or replace function public.owns_field(p_field_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.fields f
    where f.id = p_field_id and f.farmer_id = auth.uid()
  );
$$;

create or replace function public.owns_conversation(p_conversation_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.ai_conversations c
    where c.id = p_conversation_id and c.farmer_id = auth.uid()
  );
$$;

create or replace function public.in_own_village(p_village_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.farmer_profiles p
    where p.id = auth.uid() and p.village_id = p_village_id
  );
$$;

-- Enable RLS everywhere ----------------------------------------------------
alter table public.states enable row level security;
alter table public.districts enable row level security;
alter table public.blocks enable row level security;
alter table public.panchayats enable row level security;
alter table public.villages enable row level security;
alter table public.farmer_profiles enable row level security;
alter table public.fields enable row level security;
alter table public.crops enable row level security;
alter table public.field_crops enable row level security;
alter table public.todo_tasks enable row level security;
alter table public.weather_advisories enable row level security;
alter table public.crop_advice enable row level security;
alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.crop_scans enable row level security;

-- Reference data: authenticated read-only ----------------------------------
create policy states_read on public.states
  for select to authenticated using (true);
create policy districts_read on public.districts
  for select to authenticated using (true);
create policy blocks_read on public.blocks
  for select to authenticated using (true);
create policy panchayats_read on public.panchayats
  for select to authenticated using (true);
create policy villages_read on public.villages
  for select to authenticated using (true);
create policy crops_read on public.crops
  for select to authenticated using (true);
create policy crop_advice_read on public.crop_advice
  for select to authenticated using (true);

-- farmer_profiles: owner only (insert own row at signup) --------------------
create policy farmer_profiles_select_own on public.farmer_profiles
  for select to authenticated using (id = auth.uid());
create policy farmer_profiles_insert_own on public.farmer_profiles
  for insert to authenticated with check (id = auth.uid());
create policy farmer_profiles_update_own on public.farmer_profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- fields: owner only ----------------------------------------------------------
create policy fields_owner_all on public.fields
  for all to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());

-- field_crops: via owning field ------------------------------------------------
create policy field_crops_owner_all on public.field_crops
  for all to authenticated
  using (public.owns_field(field_id))
  with check (public.owns_field(field_id));

-- todo_tasks: owner only ---------------------------------------------------------
create policy todo_tasks_owner_all on public.todo_tasks
  for all to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());

-- weather_advisories: read own-village rows; writes via service role only -------
create policy weather_advisories_read_own_village on public.weather_advisories
  for select to authenticated using (public.in_own_village(village_id));

-- ai_conversations / ai_messages: owner only --------------------------------------
create policy ai_conversations_owner_all on public.ai_conversations
  for all to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());
create policy ai_messages_owner_all on public.ai_messages
  for all to authenticated
  using (public.owns_conversation(conversation_id))
  with check (public.owns_conversation(conversation_id));

-- crop_scans: owner only ------------------------------------------------------------
create policy crop_scans_owner_all on public.crop_scans
  for all to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());
