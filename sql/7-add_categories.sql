-- Create categories enum type
do $$
begin
  if not exists (select 1 from pg_type where typname = 'categories') then
    create type public.categories as enum (
      'Pharmacy',
      'Grocery',
      'Pet',
      'Craft',
      'Electronics',
      'Clothing',
      'Hardware',
      'Other'
    );
  end if;
end $$;

-- Add category column to list_items
alter table public.list_items
  add column if not exists category public.categories not null default 'Other';

-- Add category column to recurring_items
alter table public.recurring_items
  add column if not exists category public.categories not null default 'Other';
