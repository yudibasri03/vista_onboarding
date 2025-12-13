/*
  # Add Admin Role System

  ## Changes
  
  1. New Table
    - `user_roles` - Stores user roles (admin or client)
      - `user_id` (uuid, reference to auth.users)
      - `role` (text) - 'admin' or 'client'
      - `created_at` (timestamptz)
  
  2. Security
    - Enable RLS on user_roles table
    - Update all existing RLS policies to allow admin full access
    - Admins can view and manage all client data
    - Clients can only view their own data
    - Add helper function to check if user is admin
  
  3. Notes
    - Default role for new users is 'client'
    - Admins have full read/write access across all tables
    - First admin user can be created manually via INSERT statement
*/

-- Create user_roles table
CREATE TABLE IF NOT EXISTS user_roles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'client' CHECK (role IN ('admin', 'client')),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on user_roles
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- RLS policy for user_roles (users can view own role, admins can view all)
CREATE POLICY "Users can view own role"
  ON user_roles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Only admins can insert/update roles
CREATE POLICY "Admins can manage roles"
  ON user_roles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- Create helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Create helper function to automatically create user_role on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO user_roles (user_id, role)
  VALUES (NEW.id, 'client');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update RLS policies for clients table to include admin access
DROP POLICY IF EXISTS "Users can view own client data" ON clients;
DROP POLICY IF EXISTS "Users can insert own client data" ON clients;
DROP POLICY IF EXISTS "Users can update own client data" ON clients;

CREATE POLICY "Users can view client data"
  ON clients FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Users can insert own client data"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id OR is_admin());

CREATE POLICY "Users can update client data"
  ON clients FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id OR is_admin())
  WITH CHECK (auth.uid() = user_id OR is_admin());

CREATE POLICY "Admins can delete client data"
  ON clients FOR DELETE
  TO authenticated
  USING (is_admin());

-- Update RLS policies for client_onboarding_progress
DROP POLICY IF EXISTS "Users can view own progress" ON client_onboarding_progress;
DROP POLICY IF EXISTS "Users can update own progress" ON client_onboarding_progress;

CREATE POLICY "Users can view progress"
  ON client_onboarding_progress FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    ) OR is_admin()
  );

CREATE POLICY "Users can insert progress"
  ON client_onboarding_progress FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    ) OR is_admin()
  );

CREATE POLICY "Users can update progress"
  ON client_onboarding_progress FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    ) OR is_admin()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    ) OR is_admin()
  );

-- Update RLS policies for documents
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
DROP POLICY IF EXISTS "Users can insert own documents" ON documents;

CREATE POLICY "Users can view documents"
  ON documents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = auth.uid()
    ) OR is_admin()
  );

CREATE POLICY "Users can insert documents"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = auth.uid()
    ) OR is_admin()
  );

CREATE POLICY "Admins can update documents"
  ON documents FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Admins can delete documents"
  ON documents FOR DELETE
  TO authenticated
  USING (is_admin());

-- Update RLS policies for notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;

CREATE POLICY "Users can view notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Users can update notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id OR is_admin())
  WITH CHECK (auth.uid() = user_id OR is_admin());

CREATE POLICY "Admins can insert notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Admins can delete notifications"
  ON notifications FOR DELETE
  TO authenticated
  USING (is_admin());

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);

-- Example: Create first admin user (uncomment and modify as needed)
-- First, create the user in Supabase Auth Dashboard, then run:
-- INSERT INTO user_roles (user_id, role)
-- SELECT id, 'admin'
-- FROM auth.users
-- WHERE email = 'admin@example.com'
-- ON CONFLICT (user_id) DO UPDATE SET role = 'admin';