# Implementation Plan - Family Grocery App

## Phase 1: Setup & Infrastructure
Setup of supabase project and nuxt basic app is completed at the time of this writing.

## Phase 2: Authentication & Profile
1. **Login Page:**
    - Implement Nuxt UI based login form.
    - Support Email/Password.
    - Support Magic Link.
2. **Middleware:**
    - Setup auth middleware to protect routes.
3. **Profile Management:**
    - Allow users to set their display name (needed for headers).

## Phase 3: Recurring Items (Personal Tab)
1. **View:** 
    - List personal recurring items.
    - Show "frequency" and "last bought" info.
2. **Actions:**
    - Add new recurring item (Modal).
    - Delete recurring item.
    - "Add to Shopping List" button.

## Phase 4: Shared Shopping List (Main View)
1. **View:**
    - Aggregate all `shopping_list` items.
    - Group by `profiles.display_name`.
2. **Actions:**
    - Add custom item to list (not necessarily recurring).
    - "Mark as bought" (Delete + update recurring if linked).
    - "Mark all as bought" (Global action).

## Phase 5: UI/UX & Mobile Optimization
1. **Layout:**
    - Bottom navigation for mobile.
    - Responsive containers.
    - Nuxt UI Color mode support.
2. **Feedback:**
    - Loading states.
    - Toast notifications for actions.

## Phase 6: Testing & Refinement
1. **Functional Testing:**
    - Verify RLS policies (users shouldn't delete each other's recurring items).
    - Verify shared list visibility.
2. **Edge Cases:**
    - Magic link flow.
    - Empty states.
