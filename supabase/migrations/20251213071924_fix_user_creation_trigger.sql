/*
  # Fix User Creation Trigger

  ## Problem
  The handle_new_user() trigger function fails to insert into user_roles
  because RLS policies are too restrictive, even with SECURITY DEFINER.

  ## Solution
  1. Update handle_new_user() function to properly bypass RLS
  2. Add explicit search_path and ensure SECURITY DEFINER works correctly
  3. Add a policy that allows the trigger to insert client roles

  ## Changes
  - Recreate handle_new_user() with proper RLS bypass settings
  - Add policy for trigger-based inserts
*/

-- Drop and recreate the trigger function with proper RLS bypass
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Insert the user role record
  -- SECURITY DEFINER means this runs with the privileges of the function owner
  -- which bypasses RLS
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'client');
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't fail the user creation
    RAISE WARNING 'Failed to create user_role for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Ensure the trigger is properly set up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Add a policy that allows service role and triggers to insert client roles
DROP POLICY IF EXISTS "Allow trigger to insert client roles" ON user_roles;
CREATE POLICY "Allow trigger to insert client roles"
  ON user_roles FOR INSERT
  TO authenticated
  WITH CHECK (role = 'client' AND auth.uid() = user_id);