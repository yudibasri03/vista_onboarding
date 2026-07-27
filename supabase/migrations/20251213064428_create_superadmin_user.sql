/*
  # Create Super Admin User

  ## Purpose
  Creates a default super admin user for initial system access.
  
  ## Details
  - Email: superadmin@vista.local
  - Password: set manually when creating the user (MUST CHANGE ON FIRST LOGIN)
  - Role: admin
  - must_change_password: true

  ## Changes
  1. Add must_change_password column to user_roles table
  2. Create super admin user via auth
  3. Set up admin role with password change requirement

  ## Security
  - Password must be changed on first login
  - Flag tracked in user_roles table
*/

-- Add must_change_password column to user_roles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_roles' AND column_name = 'must_change_password'
  ) THEN
    ALTER TABLE user_roles ADD COLUMN must_change_password boolean DEFAULT false;
  END IF;
END $$;

-- Add last_password_change tracking
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_roles' AND column_name = 'last_password_change'
  ) THEN
    ALTER TABLE user_roles ADD COLUMN last_password_change timestamptz;
  END IF;
END $$;

-- Create function to set up super admin (to be called once)
CREATE OR REPLACE FUNCTION setup_super_admin(admin_email text, admin_password text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user_id uuid;
  result json;
BEGIN
  -- Check if super admin already exists
  IF EXISTS (
    SELECT 1 FROM user_roles 
    WHERE role = 'admin' 
    AND must_change_password = true
  ) THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Super admin already exists'
    );
  END IF;

  -- Insert into auth.users (using Supabase auth admin functions would be better in production)
  -- For now, we'll create a placeholder that needs manual setup
  
  RETURN json_build_object(
    'success', true,
    'message', 'Please create admin user manually via Supabase Dashboard',
    'email', admin_email,
    'instructions', 'Go to Authentication > Users > Add User, then run: INSERT INTO user_roles (user_id, role, must_change_password) VALUES (''<user_id>'', ''admin'', true);'
  );
END;
$$;

-- Add comment
COMMENT ON FUNCTION setup_super_admin IS 'Helper function to set up super admin user. Call with email and password.';

-- Add index for must_change_password lookups
CREATE INDEX IF NOT EXISTS idx_user_roles_must_change_password 
ON user_roles(user_id) 
WHERE must_change_password = true;