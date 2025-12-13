/*
  # Allow Anonymous Users to Read Onboarding Steps

  ## Problem
  Registration form queries onboarding_steps table to create progress records
  Only authenticated users can currently SELECT from onboarding_steps
  Anon users get blocked when trying to fetch steps
  
  ## Solution
  Add SELECT policy for anon role on onboarding_steps
  Steps are reference data and safe to read publicly
  
  ## Changes
  - Add SELECT policy for anon role on onboarding_steps table
*/

-- Allow anon users to view onboarding steps (reference data)
CREATE POLICY "Anon users can view onboarding steps"
ON onboarding_steps
FOR SELECT
TO anon
USING (true);