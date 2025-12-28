create policy "Enable all for authenticated users only" on public.list_items as permissive for all to authenticated using (true);
create policy "Enable All Actions By Created By" on public.recurring_items as permissive for all to public using ((( SELECT auth.uid() AS uid) = created_by)) with check ((( SELECT auth.uid() AS uid) = created_by));
create policy "Enable read access for all users" on public.recurring_items as permissive for select to public using (true);
create policy "Enable update access for all users" on public.recurring_items as permissive for update to authenticated using (true);
create policy "Enable read access for all users" on public.user_profile as permissive for select to public using (true);
