/*
  # Remove Blocking Insert Policy

  ## Problem
  The "Service role can insert user roles" policy has WITH CHECK (false)
  which blocks all authenticated user inserts, even when the trigger
  should be allowed to insert.

  ## Solution
  Drop the blocking policy since we now have:
  - "Allow trigger to insert client roles" for normal signups
  - "Service role can insert admin" for admin creation

  ## Changes
  - Drop the blocking INSERT policy
*/

-- Drop the blocking policy
DROP POLICY IF EXISTS "Service role can insert user roles" ON user_roles;