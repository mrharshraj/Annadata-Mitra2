-- Phase 2 seed: deterministic reference data (safe to re-run).
-- Conventions: every insert is idempotent via ON CONFLICT DO NOTHING on the
-- unique constraints from 0001; FKs resolve through subselects, never
-- hardcoded UUIDs. Village coordinates are APPROXIMATE samples for
-- weather-mapping development, not survey data.

-- States (starter set; extend with the same pattern) ----------------------------
insert into public.states (name, code) values
  ('Bihar', 'BR'),
  ('Haryana', 'HR'),
  ('Uttar Pradesh', 'UP'),
  ('Punjab', 'PB'),
  ('Madhya Pradesh', 'MP'),
  ('Rajasthan', 'RJ'),
  ('West Bengal', 'WB'),
  ('Maharashtra', 'MH')
on conflict (code) do nothing;

-- Bihar: all 38 districts (Census 2011 list) ------------------------------------
insert into public.districts (state_id, name)
select (select id from public.states where code = 'BR'), d
from (values
  ('Araria'), ('Arwal'), ('Aurangabad'), ('Banka'), ('Begusarai'),
  ('Bhagalpur'), ('Bhojpur'), ('Buxar'), ('Darbhanga'),
  ('East Champaran'), ('Gaya'), ('Gopalganj'), ('Jamui'), ('Jehanabad'),
  ('Kaimur'), ('Katihar'), ('Khagaria'), ('Kishanganj'), ('Lakhisarai'),
  ('Madhepura'), ('Madhubani'), ('Munger'), ('Muzaffarpur'), ('Nalanda'),
  ('Nawada'), ('Patna'), ('Purnia'), ('Rohtas'), ('Saharsa'), ('Samastipur'),
  ('Saran'), ('Sheikhpura'), ('Sheohar'), ('Sitamarhi'), ('Siwan'),
  ('Supaul'), ('Vaishali'), ('West Champaran')
) as t(d)
on conflict (state_id, name) do nothing;

-- Haryana: sample districts incl. the prototype's Karnal ------------------------
insert into public.districts (state_id, name)
select (select id from public.states where code = 'HR'), d
from (values
  ('Karnal'), ('Kurukshetra'), ('Panipat'), ('Ambala'), ('Hisar')
) as t(d)
on conflict (state_id, name) do nothing;

-- Blocks (sample; extend per district as rollout proceeds) -----------------------
insert into public.blocks (district_id, name)
select (select id from public.districts
         where name = 'Nalanda'
           and state_id = (select id from public.states where code = 'BR')), b
from (values ('Biharsharif'), ('Rajgir'), ('Harnaut')) as t(b)
on conflict (district_id, name) do nothing;

insert into public.blocks (district_id, name)
select (select id from public.districts
         where name = 'Karnal'
           and state_id = (select id from public.states where code = 'HR')), b
from (values ('Nilokheri'), ('Karnal')) as t(b)
on conflict (district_id, name) do nothing;

-- Panchayats (sample names; marked sample in docs) ---------------------------------
insert into public.panchayats (block_id, name)
select (select id from public.blocks
         where name = 'Biharsharif'
           and district_id = (select id from public.districts where name = 'Nalanda')), p
from (values ('Sohsarai'), ('Dhekpura')) as t(p)
on conflict (block_id, name) do nothing;

insert into public.panchayats (block_id, name)
select (select id from public.blocks
         where name = 'Nilokheri'
           and district_id = (select id from public.districts where name = 'Karnal')), p
from (values ('Nilokheri'), ('Taraori')) as t(p)
on conflict (block_id, name) do nothing;

insert into public.panchayats (block_id, name)
select (select id from public.blocks
         where name = 'Rajgir'
           and district_id = (select id from public.districts where name = 'Nalanda')), p
from (values ('Rajgir')) as t(p)
on conflict (block_id, name) do nothing;

-- Villages (approximate coordinates, development samples) ---------------------------
insert into public.villages (panchayat_id, name, latitude, longitude)
select
  (select id from public.panchayats
    where name = 'Nilokheri'
      and block_id = (select id from public.blocks where name = 'Nilokheri')),
  'Nilokheri', 29.9368, 76.9237
where not exists (
  select 1 from public.villages v
  join public.panchayats p on p.id = v.panchayat_id
  join public.blocks b on b.id = p.block_id
  where v.name = 'Nilokheri' and b.name = 'Nilokheri'
);

insert into public.villages (panchayat_id, name, latitude, longitude)
select
  (select id from public.panchayats
    where name = 'Taraori'
      and block_id = (select id from public.blocks where name = 'Nilokheri')),
  'Taraori', 29.7833, 76.9437
where not exists (
  select 1 from public.villages v where v.name = 'Taraori'
);

insert into public.villages (panchayat_id, name, latitude, longitude)
select
  (select id from public.panchayats
    where name = 'Rajgir'
      and block_id = (select id from public.blocks where name = 'Rajgir')),
  'Rajgir', 25.0267, 85.4189
where not exists (
  select 1 from public.villages v where v.name = 'Rajgir'
);

insert into public.villages (panchayat_id, name, latitude, longitude)
select
  (select id from public.panchayats
    where name = 'Sohsarai'
      and block_id = (select id from public.blocks where name = 'Biharsharif')),
  'Sohsarai', 25.1987, 85.5164
where not exists (
  select 1 from public.villages v where v.name = 'Sohsarai'
);

-- Crop catalog -----------------------------------------------------------------------
insert into public.crops (name, crop_type, season) values
  ('Wheat', 'cereal', 'Rabi'),
  ('Paddy', 'cereal', 'Kharif'),
  ('Mustard', 'oilseed', 'Rabi'),
  ('Potato', 'vegetable', 'Rabi'),
  ('Maize', 'cereal', 'Kharif'),
  ('Sugarcane', 'cash', 'Perennial'),
  ('Barley', 'cereal', 'Rabi'),
  ('Chickpea', 'pulse', 'Rabi'),
  ('Cotton', 'cash', 'Kharif'),
  ('Soybean', 'oilseed', 'Kharif')
on conflict (name) do nothing;

-- Starter agronomy notes ---------------------------------------------------------------
insert into public.crop_advice (crop_id, title, advice_text)
select (select id from public.crops where name = 'Wheat'),
  'Postpone irrigation before forecast rain',
  'If more than 10 mm rain is forecast in 24 hours, delay irrigation to avoid waterlogging during tillering.'
where exists (select 1 from public.crops where name = 'Wheat')
  and not exists (
    select 1 from public.crop_advice a
    join public.crops c on c.id = a.crop_id
    where c.name = 'Wheat' and a.title = 'Postpone irrigation before forecast rain'
  );

insert into public.crop_advice (crop_id, title, advice_text)
select (select id from public.crops where name = 'Mustard'),
  'Scout for aphids in humid spells',
  'Check tender shoots and buds twice a week during flowering; humid weather favours aphid buildup.'
where exists (select 1 from public.crops where name = 'Mustard')
  and not exists (
    select 1 from public.crop_advice a
    join public.crops c on c.id = a.crop_id
    where c.name = 'Mustard' and a.title = 'Scout for aphids in humid spells'
  );
