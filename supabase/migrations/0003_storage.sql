-- Phase 2 migration 0003: private Storage bucket for crop scan images.
-- Objects live under `<auth.uid>/<safe-filename>`; farmers manage only
-- their own prefix. Nothing here is public. Image bytes never go into
-- Postgres (only the object path is stored in public.crop_scans).

insert into storage.buckets (id, name, public)
values ('crop-scans', 'crop-scans', false)
on conflict (id) do nothing;

create policy "crop-scans insert own prefix"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'crop-scans'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "crop-scans read own prefix"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'crop-scans'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "crop-scans update own prefix"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'crop-scans'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'crop-scans'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "crop-scans delete own prefix"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'crop-scans'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
