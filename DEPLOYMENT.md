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


## Sevalla Deployment
I chose to deploy using [Sevalla](https://sevalla.com/) using their static site generation.
To use this, ensure that your SUPABASE_URL and SUPABASE_KEY environment variables are correctly set.
Sevalla uses the `npm run generate` command to generate the static site.
