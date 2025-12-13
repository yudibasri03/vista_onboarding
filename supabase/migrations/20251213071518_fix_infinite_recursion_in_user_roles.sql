/*
  # Fix Infinite Recursion in user_roles RLS Policy

  ## Problem
  The "Admins can manage roles" policy on user_roles table queries user_roles itself,
  causing infinite recursion when checking permissions.

  ## Solution
  1. Drop the problematic recursive policy
  2. Create a non-recursive admin policy that uses service role bypass
  3. Keep the "Users can view own role" policy (no recursion issue)
  4. Update is_admin() function to properly bypass RLS

  ## Changes
  - Drop "Admins can manage roles" policy
  - Recreate is_admin() function with proper RLS bypass
  - Add separate INSERT and UPDATE policies for user_roles that don't recurse
*/

-- Drop the problematic recursive policy
DROP POLICY IF EXISTS "Admins can manage roles" ON user_roles;

-- Recreate is_admin() function with explicit RLS bypass
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
DECLARE
  user_role text;
BEGIN
  -- Direct query with SECURITY DEFINER bypasses RLS
  SELECT role INTO user_role
  FROM user_roles
  WHERE user_id = auth.uid()
  LIMIT 1;

  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Create non-recursive policies for user_roles management
-- Only service role can INSERT new roles (via edge function or manual insert)
CREATE POLICY "Service role can insert user roles"
  ON user_roles FOR INSERT
  TO authenticated
  WITH CHECK (false); -- Regular users cannot insert, only service role bypasses this

-- Only service role can UPDATE roles (via edge function or manual update)
CREATE POLICY "Service role can update user roles"
  ON user_roles FOR UPDATE
  TO authenticated
  USING (false) -- Regular users cannot update, only service role bypasses this
  WITH CHECK (false);

-- Service role can DELETE roles
CREATE POLICY "Service role can delete user roles"
  ON user_roles FOR DELETE
  TO authenticated
  USING (false); -- Regular users cannot delete, only service role bypasses this

-- Note: The existing "Users can view own role" policy remains and works fine
-- because it doesn't query user_roles recursively when checking SELECT permissions