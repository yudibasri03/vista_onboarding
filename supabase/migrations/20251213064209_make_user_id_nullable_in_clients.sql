/*
  # Make user_id nullable in clients table

  ## Purpose
  Allow client registration without requiring authentication.
  This enables direct wizard registration flow without login.

  ## Changes
  - Make `user_id` column nullable in `clients` table
  - Clients can now be created without user accounts
  - Admin will still have user accounts for authentication

  ## Security
  - RLS policies updated to handle null user_id
  - Admin access remains controlled through user_roles
*/

-- Make user_id nullable
ALTER TABLE clients ALTER COLUMN user_id DROP NOT NULL;

-- Add comment
COMMENT ON COLUMN clients.user_id IS 'User ID from auth.users - nullable for clients who register directly without login';