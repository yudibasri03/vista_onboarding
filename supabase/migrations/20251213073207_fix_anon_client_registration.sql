/*
  # Fix Anonymous Client Registration

  ## Problem
  Despite having "Allow client registration" policy with role public,
  anon users still cannot insert to clients table
  
  ## Root Cause
  The WITH CHECK condition uses auth.uid() which might cause issues
  when evaluated for anon users
  
  ## Solution
  Create specific policy for anon role with simpler condition
  Allow anon users to insert only when user_id IS NULL
  
  ## Changes
  - Add dedicated INSERT policy for anon role
  - Simpler condition: only check user_id IS NULL
*/

-- Drop the existing public policy as it's not working for anon
DROP POLICY IF EXISTS "Allow client registration" ON clients;

-- Create policy specifically for anon users (public registration form)
CREATE POLICY "Anon users can register"
ON clients
FOR INSERT
TO anon
WITH CHECK (user_id IS NULL);

-- Create policy for authenticated users
CREATE POLICY "Authenticated users can insert own client data"
ON clients
FOR INSERT
TO authenticated
WITH CHECK (
  (auth.uid() = user_id) OR is_admin()
);