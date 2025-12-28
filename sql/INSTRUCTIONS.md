# SQL Execution Instructions

This project is designed to be run in **Supabase**. These scripts manage the database schema for the Groceries App.

## Prerequisites

Before running any of the scripts below, ensure that:
1. You have a **Supabase** project set up.
2. The `auth.users` table exists. This is typically created automatically by Supabase when Auth is enabled. Many of these scripts have foreign key constraints referencing `auth.users(id)`.

## Execution Order

Run the following SQL scripts in the specified order using the **Supabase SQL Editor**.

### 1. User Profiles
Run `1-user_profile.sql` first.
- **File:** `sql/1-user_profile.sql`
- **Purpose:** Creates the `public.user_profile` table which references `auth.users`.

### 2. Recurring Items
Run `2-recurring_items.sql` second.
- **File:** `sql/2-recurring_items.sql`
- **Purpose:** Creates the `public.recurring_items` table.

### 3. List Items
Run `3-list_items.sql` third.
- **File:** `sql/3-list_items.sql`
- **Purpose:** Creates the `public.list_items` table with foreign key references to `recurring_items`, `auth.users`, and `user_profile`.

### 4. RLS Policies
Run `4-rls_policies.sql` last.
- **File:** `sql/4-rls_policies.sql`
- **Purpose:** Sets up Row Level Security (RLS) policies for all created tables.
