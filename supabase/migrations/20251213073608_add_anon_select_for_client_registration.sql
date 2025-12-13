/*
  # Add SELECT Policy for Anonymous Client Registration

  ## Problem
  Form does .insert().select().single() which requires SELECT permission
  Currently only authenticated users can SELECT from clients table
  Anon users can INSERT but cannot SELECT the returned row
  
  ## Solution
  Add SELECT policy for anon users to read their just-inserted client record
  Restrict to only records where user_id IS NULL (unlinked clients)
  
  ## Changes
  - Add SELECT policy for anon role
  - Allow reading only unlinked client records (user_id IS NULL)
*/

-- Allow anon users to SELECT unlinked client records
-- This is needed for .insert().select() operations
CREATE POLICY "Anon users can view unlinked clients"
ON clients
FOR SELECT
TO anon
USING (user_id IS NULL);