-- Phase 2 migration 0002: Row Level Security (spec revision).
-- Farmers access ONLY their own private rows. Reference catalogs
-- (locations, crops, crop_advice) are readable by authenticated users.
-- Weather advisories are written by the backend service role (Phase 8);
-- farmers read rows for their own village or assigned profile.
-- No private table uses an open `using (true)` policy.

-- Ownership helpers -------------------------------------------------------
create or replace function public.owns_field(p_field_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.fields f
    where f.id = p_field_id and f.profile_id = auth.uid()
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
    where c.id = p_conversation_id and c.profile_id = auth.uid()
  );
$$;

create or replace function public.in_own_village(p_village_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.village_id = p_village_id
  );
$$;

-- Enable RLS everywhere ----------------------------------------------------
alter table public.states enable row level security;
alter table public.districts enable row level security;
alter table public.blocks enable row level security;
alter table public.panchayats enable row level security;
alter table public.villages enable row level security;
alter table public.profiles enable row level security;
alter table public.fields enable row level security;
alter table public.crops enable row level security;
alter table public.field_crops enable row level security;
alter table public.tasks enable row level security;
alter table public.weather_advisories enable row level security;
alter table public.crop_advice enable row level security;
alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.crop_scans enable row level security;

-- Reference data: authenticated read-only ----------------------------------
-- (Scoped to authenticated users; these carry no farmer-private data.)
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

-- profiles: owner only (insert own row at signup) ----------------------------
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_delete_own on public.profiles
  for delete to authenticated using (id = auth.uid());

-- fields: owner only ----------------------------------------------------------
create policy fields_select_own on public.fields
  for select to authenticated using (profile_id = auth.uid());
create policy fields_insert_own on public.fields
  for insert to authenticated with check (profile_id = auth.uid());
create policy fields_update_own on public.fields
  for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy fields_delete_own on public.fields
  for delete to authenticated using (profile_id = auth.uid());

-- field_crops: crops assigned to the farmer's own fields -----------------------
create policy field_crops_select_own on public.field_crops
  for select to authenticated using (public.owns_field(field_id));
create policy field_crops_insert_own on public.field_crops
  for insert to authenticated with check (public.owns_field(field_id));
create policy field_crops_update_own on public.field_crops
  for update to authenticated
  using (public.owns_field(field_id))
  with check (public.owns_field(field_id));
create policy field_crops_delete_own on public.field_crops
  for delete to authenticated using (public.owns_field(field_id));

-- tasks: owner only ---------------------------------------------------------------
create policy tasks_select_own on public.tasks
  for select to authenticated using (profile_id = auth.uid());
create policy tasks_insert_own on public.tasks
  for insert to authenticated with check (profile_id = auth.uid());
create policy tasks_update_own on public.tasks
  for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy tasks_delete_own on public.tasks
  for delete to authenticated using (profile_id = auth.uid());

-- weather_advisories: own village or assigned profile; service role writes -------
create policy weather_advisories_read_mine on public.weather_advisories
  for select to authenticated using (
    public.in_own_village(village_id) or profile_id = auth.uid()
  );

-- ai_conversations / ai_messages: owner only ----------------------------------------
create policy ai_conversations_select_own on public.ai_conversations
  for select to authenticated using (profile_id = auth.uid());
create policy ai_conversations_insert_own on public.ai_conversations
  for insert to authenticated with check (profile_id = auth.uid());
create policy ai_conversations_update_own on public.ai_conversations
  for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy ai_conversations_delete_own on public.ai_conversations
  for delete to authenticated using (profile_id = auth.uid());

create policy ai_messages_select_own on public.ai_messages
  for select to authenticated
  using (public.owns_conversation(conversation_id));
create policy ai_messages_insert_own on public.ai_messages
  for insert to authenticated
  with check (public.owns_conversation(conversation_id));
create policy ai_messages_delete_own on public.ai_messages
  for delete to authenticated
  using (public.owns_conversation(conversation_id));

-- crop_scans: owner only ----------------------------------------------------------------
create policy crop_scans_select_own on public.crop_scans
  for select to authenticated using (profile_id = auth.uid());
create policy crop_scans_insert_own on public.crop_scans
  for insert to authenticated with check (profile_id = auth.uid());
create policy crop_scans_update_own on public.crop_scans
  for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy crop_scans_delete_own on public.crop_scans
  for delete to authenticated using (profile_id = auth.uid());
