/*
  # Fix Multiple Permissive Policies

  ## Problem
  Some tables have duplicate permissive policies that cause Supabase warnings
  - client_onboarding_progress has redundant INSERT policies
  - notifications and user_roles have multiple policies (but they're intentional)
  
  ## Solution
  Remove redundant policies and keep the most optimized versions
  
  ## Changes
  - Remove "Users can insert own progress" (redundant with "Users can insert progress")
  - Keep other multiple policies as they serve different purposes
*/

-- Remove redundant policy on client_onboarding_progress
DROP POLICY IF EXISTS "Users can insert own progress" ON client_onboarding_progress;