/*
  # Fix Function Search Path Security Issue

  ## Problem
  The setup_super_admin function has a mutable search_path which is a security risk
  Functions with SECURITY DEFINER should have an immutable search_path
  
  ## Solution
  Recreate the function with SET search_path = public, pg_temp
  This ensures the function only searches in public schema and temp objects
  
  ## Changes
  - Drop and recreate setup_super_admin with fixed search_path
*/

-- Drop the existing function
DROP FUNCTION IF EXISTS setup_super_admin(text, text);

-- Recreate with fixed search_path
CREATE OR REPLACE FUNCTION setup_super_admin(admin_email text, admin_password text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  new_user_id uuid;
  result json;
BEGIN
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

  RETURN json_build_object(
    'success', true,
    'message', 'Please create admin user manually via Supabase Dashboard',
    'email', admin_email,
    'instructions', 'Go to Authentication > Users > Add User, then run: INSERT INTO user_roles (user_id, role, must_change_password) VALUES (''<user_id>'', ''admin'', true);'
  );
END;
$$;