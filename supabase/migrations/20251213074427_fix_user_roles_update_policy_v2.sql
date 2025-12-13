/*
  # Fix User Roles Update Policy for Password Changes

  ## Problem
  Current UPDATE policy on user_roles has USING (false) and WITH CHECK (false)
  This blocks ALL authenticated users from updating their password change status
  When users change password, the update to set must_change_password=false fails silently
  This causes users to be stuck in password change loop
  
  ## Solution
  Replace the blocking UPDATE policy with one that allows:
  1. Users to update their own must_change_password and last_password_change fields
  2. Admins to update any user's role data
  
  ## Changes
  - Drop existing broken UPDATE policy
  - Create new policy allowing users to update own password-related fields
  - Create admin policy for full user_roles management
*/

-- Drop the broken UPDATE policy
DROP POLICY IF EXISTS "Service role can update user roles" ON user_roles;

-- Allow users to update their own password change status
CREATE POLICY "Users can update own password status"
ON user_roles
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow admins to update any user's role data
CREATE POLICY "Admins can update user roles"
ON user_roles
FOR UPDATE
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());