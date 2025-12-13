/*
  # Fix Anonymous Onboarding Progress

  ## Problem
  Ensure anon users can insert onboarding progress records
  for newly registered clients with user_id = NULL
  
  ## Solution
  Add specific policy for anon role (in addition to existing public policy)
  
  ## Changes
  - Add dedicated INSERT policy for anon role
  - Allow insert if associated client has user_id = NULL
*/

-- Drop existing public policy and recreate for anon specifically
DROP POLICY IF EXISTS "Allow progress for public registration" ON client_onboarding_progress;

-- Create policy for anon users (public registration form)
CREATE POLICY "Anon users can insert progress for new registrations"
ON client_onboarding_progress
FOR INSERT
TO anon
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM clients
    WHERE clients.id = client_onboarding_progress.client_id
    AND clients.user_id IS NULL
  )
);