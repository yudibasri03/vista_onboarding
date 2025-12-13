/*
  # Add Service Role Bypass for Admin Setup

  ## Purpose
  Allow service role to insert admin user during initial setup.
  
  ## Changes
  1. Add policy to allow service role to insert admin users
  
  ## Security
  - Service role key should be kept secure
  - Only used for initial admin setup
*/

-- Drop policy if exists
DROP POLICY IF EXISTS "Service role can insert admin" ON user_roles;

-- Add policy for service role to insert admin
CREATE POLICY "Service role can insert admin"
  ON user_roles
  FOR INSERT
  TO service_role
  WITH CHECK (role = 'admin');