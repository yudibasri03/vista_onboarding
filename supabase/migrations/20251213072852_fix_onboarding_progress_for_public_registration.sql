/*
  # Fix Onboarding Progress for Public Registration

  ## Problem
  client_onboarding_progress policies only allow authenticated users to insert
  But public registration form (unauthenticated) needs to insert progress records
  for newly created clients with user_id = NULL
  
  ## Solution
  Add policy to allow public/unauthenticated inserts for clients with user_id = NULL
  
  ## Changes
  - Add new INSERT policy for public registration flow
  - Allow insert if the associated client has user_id = NULL
*/

-- Allow public to insert onboarding progress for unregistered clients (user_id = NULL)
CREATE POLICY "Allow progress for public registration"
ON client_onboarding_progress
FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM clients
    WHERE clients.id = client_onboarding_progress.client_id
    AND clients.user_id IS NULL
  )
);