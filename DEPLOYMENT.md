# Deployment Overview

This document provides a quick guide for deploying the Family Grocery App. The application is built with Nuxt 4 and uses Supabase for authentication and database management.

## Deployment Steps

### 1. Supabase Setup
Before deploying the frontend, you must configure your Supabase instance:
- **Database Schema**: Execute the SQL scripts located in the `sql/` directory in the following order:
    1. `1-user_profile.sql`
    2. `2-recurring_items.sql`
    3. `3-list_items.sql`
    4. `4-rls_policies.sql`
  Refer to `sql/INSTRUCTIONS.md` for detailed database setup instructions.
- **Authentication**: Enable Email/Password or Magic Link providers in the Supabase Auth settings.

### 2. Environment Variables
Ensure the following environment variables are configured in your deployment environment (e.g., Vercel, Netlify, or a VPS):
- `SUPABASE_URL`: Your Supabase project URL.
- `SUPABASE_KEY`: Your Supabase anonymous API key.

Refer to `.env.example` for the required format.

### 3. Build and Deploy
The application can be built using:
```bash
npm run build
```
As a Nuxt application, it can be deployed to various platforms:
- **Vercel/Netlify**: Connect your repository; the build command and output directory are usually detected automatically.
- **Node.js Server**: Run `node .output/server/index.mjs` after building.
- **Static Hosting**: If configured for SSG, use `npm run generate`.

## Post-Deployment
- Verify that Row Level Security (RLS) policies are active.
- Ensure the `auth.users` trigger (if any) or initial user profile creation is functioning correctly.

### Adding Users
Follow these steps to manually add users to the application:
1. **Create User in Supabase**: Go to the **Authentication** section in your Supabase dashboard and create a new user with an email and password.
2. **Copy User ID**: Once created, copy the **User ID** (GUID) for the new user from the user list.
3. **Add User Profile Record**: Go to the **SQL Editor** or **Table Editor** and add a record to the `user_profile` table:
   - `user_id`: Paste the GUID you copied.
   - `name`: Enter the user's name.

Example SQL for adding a profile:
```sql
insert into public.user_profile (user_id, name)
values ('USER_GUID_HERE', 'User Name');
```


## Sevalla Deployment
I chose to deploy using [Sevalla](https://sevalla.com/) using their static site generation.
To use this, ensure that your SUPABASE_URL and SUPABASE_KEY environment variables are correctly set.
Sevalla uses the `npm run generate` command to generate the static site.

After deployment, you will need to update the url for call back in supabase. 
