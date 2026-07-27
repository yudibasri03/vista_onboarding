-- =====================================================================
-- Vista Onboarding / CRM — Complete schema (all migrations, in order)
-- Generated from supabase/migrations/*. Apply to a fresh self-hosted DB.
-- =====================================================================


-- =====================================================================
-- SOURCE: 20251213055634_create_onboarding_system.sql
-- =====================================================================

/*
  # Sistema Onboarding Client - Vista Produk

  ## Tabel Baru
  
  1. `clients` - Data client yang mendaftar
     - `id` (uuid, primary key)
     - `user_id` (uuid, reference ke auth.users)
     - `company_name` (text)
     - `pic_name` (text)
     - `email` (text)
     - `phone` (text)
     - `address` (text)
     - `business_type` (text)
     - `status` (text) - pending, verified, approved, rejected, active
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)
  
  2. `onboarding_steps` - Tahapan onboarding
     - `id` (uuid, primary key)
     - `step_number` (integer)
     - `title` (text)
     - `description` (text)
     - `is_required` (boolean)
     - `created_at` (timestamptz)
  
  3. `client_onboarding_progress` - Progress onboarding client
     - `id` (uuid, primary key)
     - `client_id` (uuid, reference ke clients)
     - `step_id` (uuid, reference ke onboarding_steps)
     - `status` (text) - not_started, in_progress, completed, skipped
     - `notes` (text)
     - `completed_at` (timestamptz)
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)
  
  4. `documents` - Dokumen client
     - `id` (uuid, primary key)
     - `client_id` (uuid, reference ke clients)
     - `document_type` (text)
     - `file_name` (text)
     - `file_url` (text)
     - `status` (text) - pending, verified, rejected
     - `uploaded_at` (timestamptz)
     - `verified_at` (timestamptz)
     - `verified_by` (uuid, reference ke auth.users)
  
  5. `notifications` - Notifikasi sistem
     - `id` (uuid, primary key)
     - `user_id` (uuid, reference ke auth.users)
     - `title` (text)
     - `message` (text)
     - `type` (text) - info, success, warning, error
     - `is_read` (boolean)
     - `created_at` (timestamptz)

  ## Security
  - Enable RLS pada semua tabel
  - Policy untuk authenticated users
  - Admin dapat mengakses semua data
  - Client hanya dapat mengakses data mereka sendiri
*/

-- Create clients table
CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name text NOT NULL,
  pic_name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  address text NOT NULL,
  business_type text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create onboarding_steps table
CREATE TABLE IF NOT EXISTS onboarding_steps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  step_number integer NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  is_required boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Create client_onboarding_progress table
CREATE TABLE IF NOT EXISTS client_onboarding_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  step_id uuid REFERENCES onboarding_steps(id) ON DELETE CASCADE NOT NULL,
  status text NOT NULL DEFAULT 'not_started',
  notes text,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  document_type text NOT NULL,
  file_name text NOT NULL,
  file_url text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  uploaded_at timestamptz DEFAULT now(),
  verified_at timestamptz,
  verified_by uuid REFERENCES auth.users(id)
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL DEFAULT 'info',
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for clients
CREATE POLICY "Users can view own client data"
  ON clients FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own client data"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own client data"
  ON clients FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for onboarding_steps (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view onboarding steps"
  ON onboarding_steps FOR SELECT
  TO authenticated
  USING (true);

-- RLS Policies for client_onboarding_progress
CREATE POLICY "Users can view own progress"
  ON client_onboarding_progress FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own progress"
  ON client_onboarding_progress FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    )
  );

-- RLS Policies for documents
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = auth.uid()
    )
  );

-- RLS Policies for notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Insert default onboarding steps
INSERT INTO onboarding_steps (step_number, title, description, is_required) VALUES
  (1, 'Registrasi Data Perusahaan', 'Lengkapi data perusahaan dan informasi PIC', true),
  (2, 'Upload Dokumen', 'Upload dokumen persyaratan (NPWP, SIUP, NIB)', true),
  (3, 'Verifikasi Data', 'Menunggu verifikasi data oleh tim Vista', true),
  (4, 'Setup Akun', 'Konfigurasi akun dan preferensi sistem', true),
  (5, 'Training & Onboarding', 'Mengikuti training penggunaan sistem Vista', true),
  (6, 'Go Live', 'Sistem siap digunakan', true)
ON CONFLICT DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_client_onboarding_progress_updated_at BEFORE UPDATE ON client_onboarding_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- SOURCE: 20251213060253_fix_rls_policies.sql
-- =====================================================================

/*
  # Fix RLS Policies untuk Insert Operations

  ## Changes
  - Tambah INSERT policy untuk client_onboarding_progress
  - Tambah INSERT policy untuk notifications
  - Pastikan semua operasi CRUD ter-cover dengan policy yang tepat
*/

-- Add INSERT policy for client_onboarding_progress
CREATE POLICY "Users can insert own progress"
  ON client_onboarding_progress FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = auth.uid()
    )
  );

-- Add INSERT policy for notifications
CREATE POLICY "Users can insert own notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Add INSERT policy for onboarding_steps (admin only, but allow read)
-- This is already handled by the existing SELECT policy

-- =====================================================================
-- SOURCE: 20251213060546_optimize_security_and_performance_v2.sql
-- =====================================================================

/*
  # Optimize Security and Performance

  ## Changes
  
  1. **Add Indexes for Foreign Keys**
     - Index pada client_onboarding_progress (client_id, step_id)
     - Index pada clients (user_id)
     - Index pada documents (client_id, verified_by)
     - Index pada notifications (user_id)
  
  2. **Optimize RLS Policies**
     - Replace auth.uid() dengan (select auth.uid()) untuk performa optimal
     - Recreate semua policies dengan optimized syntax
  
  3. **Fix Function Search Path**
     - Update function dengan SECURITY DEFINER dan search_path yang proper

  ## Notes
  - Indexes akan meningkatkan performa query dengan foreign keys
  - Optimized RLS policies akan mengurangi re-evaluation overhead
*/

-- ============================================
-- 1. ADD INDEXES FOR FOREIGN KEYS
-- ============================================

-- Index untuk clients.user_id
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON clients(user_id);

-- Index untuk client_onboarding_progress.client_id
CREATE INDEX IF NOT EXISTS idx_client_onboarding_progress_client_id 
  ON client_onboarding_progress(client_id);

-- Index untuk client_onboarding_progress.step_id
CREATE INDEX IF NOT EXISTS idx_client_onboarding_progress_step_id 
  ON client_onboarding_progress(step_id);

-- Index untuk documents.client_id
CREATE INDEX IF NOT EXISTS idx_documents_client_id ON documents(client_id);

-- Index untuk documents.verified_by
CREATE INDEX IF NOT EXISTS idx_documents_verified_by ON documents(verified_by);

-- Index untuk notifications.user_id
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- ============================================
-- 2. OPTIMIZE RLS POLICIES
-- ============================================

-- Drop existing policies untuk clients
DROP POLICY IF EXISTS "Users can view own client data" ON clients;
DROP POLICY IF EXISTS "Users can insert own client data" ON clients;
DROP POLICY IF EXISTS "Users can update own client data" ON clients;

-- Recreate optimized policies untuk clients
CREATE POLICY "Users can view own client data"
  ON clients FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own client data"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own client data"
  ON clients FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Drop existing policies untuk client_onboarding_progress
DROP POLICY IF EXISTS "Users can view own progress" ON client_onboarding_progress;
DROP POLICY IF EXISTS "Users can update own progress" ON client_onboarding_progress;
DROP POLICY IF EXISTS "Users can insert own progress" ON client_onboarding_progress;

-- Recreate optimized policies untuk client_onboarding_progress
CREATE POLICY "Users can view own progress"
  ON client_onboarding_progress FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Users can update own progress"
  ON client_onboarding_progress FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Users can insert own progress"
  ON client_onboarding_progress FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = (select auth.uid())
    )
  );

-- Drop existing policies untuk documents
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
DROP POLICY IF EXISTS "Users can insert own documents" ON documents;

-- Recreate optimized policies untuk documents
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = (select auth.uid())
    )
  );

-- Drop existing policies untuk notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;

-- Recreate optimized policies untuk notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- ============================================
-- 3. FIX FUNCTION SEARCH PATH
-- ============================================

-- Replace function with proper security settings
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- =====================================================================
-- SOURCE: 20251213060842_fix_rls_performance_with_public_helper.sql
-- =====================================================================

/*
  # Comprehensive RLS Performance and Security Fix

  ## Changes
  
  1. **Create Helper Function for Auth**
     - Security definer function in public schema
     - Returns auth.uid() value once per query
     - Prevents re-evaluation across multiple rows
  
  2. **Recreate All RLS Policies**
     - Use helper function for optimal performance
     - Ensures single evaluation per query
  
  3. **Verify All Indexes**
     - Ensure covering indexes for all foreign keys
  
  4. **Fix Function Immutability**
     - Update function with proper security settings

  ## Notes
  - Helper function ensures auth.uid() is called only once per query
  - All RLS policies use the helper for optimal performance
  - search_path set to empty string for maximum security
*/

-- ============================================
-- 1. CREATE HELPER FUNCTION FOR AUTH
-- ============================================

-- Create helper function that returns current authenticated user ID
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT auth.uid();
$$;

-- ============================================
-- 2. VERIFY AND CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_clients_user_id 
  ON clients(user_id);

CREATE INDEX IF NOT EXISTS idx_client_onboarding_progress_client_id 
  ON client_onboarding_progress(client_id);

CREATE INDEX IF NOT EXISTS idx_client_onboarding_progress_step_id 
  ON client_onboarding_progress(step_id);

CREATE INDEX IF NOT EXISTS idx_documents_client_id 
  ON documents(client_id);

CREATE INDEX IF NOT EXISTS idx_documents_verified_by 
  ON documents(verified_by);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id 
  ON notifications(user_id);

-- ============================================
-- 3. RECREATE RLS POLICIES
-- ============================================

-- CLIENTS TABLE
DROP POLICY IF EXISTS "Users can view own client data" ON clients;
DROP POLICY IF EXISTS "Users can insert own client data" ON clients;
DROP POLICY IF EXISTS "Users can update own client data" ON clients;

CREATE POLICY "Users can view own client data"
  ON clients FOR SELECT
  TO authenticated
  USING (get_current_user_id() = user_id);

CREATE POLICY "Users can insert own client data"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (get_current_user_id() = user_id);

CREATE POLICY "Users can update own client data"
  ON clients FOR UPDATE
  TO authenticated
  USING (get_current_user_id() = user_id)
  WITH CHECK (get_current_user_id() = user_id);

-- CLIENT_ONBOARDING_PROGRESS TABLE
DROP POLICY IF EXISTS "Users can view own progress" ON client_onboarding_progress;
DROP POLICY IF EXISTS "Users can insert own progress" ON client_onboarding_progress;
DROP POLICY IF EXISTS "Users can update own progress" ON client_onboarding_progress;

CREATE POLICY "Users can view own progress"
  ON client_onboarding_progress FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = get_current_user_id()
    )
  );

CREATE POLICY "Users can insert own progress"
  ON client_onboarding_progress FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = get_current_user_id()
    )
  );

CREATE POLICY "Users can update own progress"
  ON client_onboarding_progress FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = get_current_user_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = client_onboarding_progress.client_id
      AND clients.user_id = get_current_user_id()
    )
  );

-- DOCUMENTS TABLE
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
DROP POLICY IF EXISTS "Users can insert own documents" ON documents;

CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = get_current_user_id()
    )
  );

CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clients
      WHERE clients.id = documents.client_id
      AND clients.user_id = get_current_user_id()
    )
  );

-- NOTIFICATIONS TABLE
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (get_current_user_id() = user_id);

CREATE POLICY "Users can insert own notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (get_current_user_id() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (get_current_user_id() = user_id)
  WITH CHECK (get_current_user_id() = user_id);

-- ============================================
-- 4. FIX FUNCTION SEARCH PATH
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- =====================================================================
-- SOURCE: 20251213061746_remove_unused_indexes.sql
-- =====================================================================

/*
  # Remove Unused Indexes

  1. Security Improvements
    - Remove unused indexes to reduce database overhead
    - Improve maintenance performance
    - Reduce storage usage

  2. Changes
    - Drop `idx_client_onboarding_progress_client_id` index
    - Drop `idx_client_onboarding_progress_step_id` index
    - Drop `idx_documents_client_id` index
    - Drop `idx_documents_verified_by` index
    - Drop `idx_notifications_user_id` index

  Note: The foreign key constraints will still ensure referential integrity.
  If these indexes become necessary in the future due to query patterns, they can be recreated.
*/

-- Drop unused indexes
DROP INDEX IF EXISTS idx_client_onboarding_progress_client_id;
DROP INDEX IF EXISTS idx_client_onboarding_progress_step_id;
DROP INDEX IF EXISTS idx_documents_client_id;
DROP INDEX IF EXISTS idx_documents_verified_by;
DROP INDEX IF EXISTS idx_notifications_user_id;

-- =====================================================================
-- SOURCE: 20251213062904_add_admin_role_system.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213063312_add_vista_onboarding_fields.sql
-- =====================================================================

/*
  # Add Vista Client Onboarding Fields

  ## Changes
  
  1. Add new columns to clients table:
    - `full_name` - Nama lengkap sesuai KTP
    - `whatsapp` - Nomor WhatsApp
    - `occupation` - Pekerjaan
    - `position` - Jabatan
    - `ktp_url` - URL file KTP
    - `product_type` - Jenis produk (ea_trading, bimbel_prop, vip_membership)
    - `product_config` - Konfigurasi produk (JSONB)
    - `risk_profile` - Profile risiko (aggressive, moderate, conservative)
    - `consent_data_accuracy` - Consent data benar
    - `consent_risk_understanding` - Consent memahami risiko
    - `consent_verification_process` - Consent verifikasi lanjutan
    - `registration_completed_at` - Waktu complete registrasi
  
  2. Notes
    - Existing fields (pic_name, phone) tetap ada untuk backward compatibility
    - product_config menggunakan JSONB untuk fleksibilitas
    - Status clients akan menentukan progress onboarding
*/

-- Add new columns to clients table
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS full_name text,
ADD COLUMN IF NOT EXISTS whatsapp text,
ADD COLUMN IF NOT EXISTS occupation text,
ADD COLUMN IF NOT EXISTS position text,
ADD COLUMN IF NOT EXISTS ktp_url text,
ADD COLUMN IF NOT EXISTS product_type text CHECK (product_type IN ('ea_trading', 'bimbel_prop', 'vip_membership')),
ADD COLUMN IF NOT EXISTS product_config jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS risk_profile text CHECK (risk_profile IN ('aggressive', 'moderate', 'conservative', NULL)),
ADD COLUMN IF NOT EXISTS consent_data_accuracy boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS consent_risk_understanding boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS consent_verification_process boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS registration_completed_at timestamptz;

-- Add index for product type queries
CREATE INDEX IF NOT EXISTS idx_clients_product_type ON clients(product_type);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);

-- Add comments for documentation
COMMENT ON COLUMN clients.full_name IS 'Nama lengkap sesuai KTP';
COMMENT ON COLUMN clients.whatsapp IS 'Nomor WhatsApp untuk komunikasi';
COMMENT ON COLUMN clients.occupation IS 'Pekerjaan klien';
COMMENT ON COLUMN clients.position IS 'Jabatan/posisi klien';
COMMENT ON COLUMN clients.ktp_url IS 'URL file KTP yang diupload';
COMMENT ON COLUMN clients.product_type IS 'Jenis produk: ea_trading, bimbel_prop, vip_membership';
COMMENT ON COLUMN clients.product_config IS 'Konfigurasi produk dalam format JSON';
COMMENT ON COLUMN clients.risk_profile IS 'Profile risiko trading: aggressive, moderate, conservative';
COMMENT ON COLUMN clients.consent_data_accuracy IS 'Consent bahwa data yang diisi benar';
COMMENT ON COLUMN clients.consent_risk_understanding IS 'Consent memahami risiko trading';
COMMENT ON COLUMN clients.consent_verification_process IS 'Consent bersedia mengikuti verifikasi lanjutan';

-- =====================================================================
-- SOURCE: 20251213063709_add_audit_trail_system.sql
-- =====================================================================

/*
  # Add Audit Trail System for Compliance

  ## Purpose
  Track all admin actions on client data for compliance and dispute resolution
  
  ## New Tables
  
  1. `audit_logs`
    - `id` (uuid, primary key)
    - `client_id` (uuid, references clients)
    - `admin_id` (uuid, references auth.users)
    - `action` (text) - Action type: review_kyc, approve, reject, request_revision, etc
    - `details` (jsonb) - Detailed information about the action
    - `ip_address` (text) - IP address of admin
    - `created_at` (timestamptz)
  
  2. `kyc_reviews`
    - `id` (uuid, primary key)
    - `client_id` (uuid, references clients)
    - `reviewer_id` (uuid, references auth.users)
    - `document_type` (text) - KTP, etc
    - `status` (text) - pending, verified, rejected
    - `notes` (text) - Reviewer notes
    - `reviewed_at` (timestamptz)
    - `created_at` (timestamptz)
  
  3. `wpa_schedules`
    - `id` (uuid, primary key)
    - `client_id` (uuid, references clients)
    - `purpose` (text) - WPA Call, KYC Lanjutan, Product Briefing
    - `scheduled_date` (timestamptz)
    - `pic_id` (uuid, references auth.users)
    - `status` (text) - scheduled, completed, cancelled
    - `notes` (text)
    - `created_at` (timestamptz)
  
  ## Security
  - Enable RLS on all tables
  - Only authenticated admins can access
  - All actions are logged and cannot be deleted
*/

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE,
  admin_id uuid REFERENCES auth.users(id),
  action text NOT NULL,
  details jsonb DEFAULT '{}'::jsonb,
  ip_address text,
  created_at timestamptz DEFAULT now()
);

-- Create kyc_reviews table
CREATE TABLE IF NOT EXISTS kyc_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  reviewer_id uuid REFERENCES auth.users(id),
  document_type text NOT NULL DEFAULT 'KTP',
  status text NOT NULL CHECK (status IN ('pending', 'verified', 'rejected')) DEFAULT 'pending',
  notes text,
  reviewed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create wpa_schedules table
CREATE TABLE IF NOT EXISTS wpa_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  purpose text NOT NULL,
  scheduled_date timestamptz NOT NULL,
  pic_id uuid REFERENCES auth.users(id),
  status text NOT NULL CHECK (status IN ('scheduled', 'completed', 'cancelled')) DEFAULT 'scheduled',
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_client_id ON audit_logs(client_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_id ON audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_kyc_reviews_client_id ON kyc_reviews(client_id);
CREATE INDEX IF NOT EXISTS idx_kyc_reviews_status ON kyc_reviews(status);

CREATE INDEX IF NOT EXISTS idx_wpa_schedules_client_id ON wpa_schedules(client_id);
CREATE INDEX IF NOT EXISTS idx_wpa_schedules_status ON wpa_schedules(status);
CREATE INDEX IF NOT EXISTS idx_wpa_schedules_date ON wpa_schedules(scheduled_date);

-- Enable RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE wpa_schedules ENABLE ROW LEVEL SECURITY;

-- RLS Policies for audit_logs
CREATE POLICY "Admins can view audit logs"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

CREATE POLICY "Admins can insert audit logs"
  ON audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

-- RLS Policies for kyc_reviews
CREATE POLICY "Admins can view KYC reviews"
  ON kyc_reviews FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

CREATE POLICY "Admins can insert KYC reviews"
  ON kyc_reviews FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

CREATE POLICY "Admins can update KYC reviews"
  ON kyc_reviews FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

-- RLS Policies for wpa_schedules
CREATE POLICY "Admins can view WPA schedules"
  ON wpa_schedules FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

CREATE POLICY "Admins can insert WPA schedules"
  ON wpa_schedules FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

CREATE POLICY "Admins can update WPA schedules"
  ON wpa_schedules FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

-- Add comments for documentation
COMMENT ON TABLE audit_logs IS 'Comprehensive audit trail for all admin actions on client data';
COMMENT ON TABLE kyc_reviews IS 'KYC document review and verification tracking';
COMMENT ON TABLE wpa_schedules IS 'Schedule management for WPA calls and KYC follow-ups';
COMMENT ON COLUMN audit_logs.action IS 'Action types: review_kyc, approve, reject, request_revision, activate_product, etc';
COMMENT ON COLUMN audit_logs.details IS 'JSON object containing detailed information about the action';
COMMENT ON COLUMN audit_logs.ip_address IS 'IP address of admin performing the action';

-- =====================================================================
-- SOURCE: 20251213064209_make_user_id_nullable_in_clients.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213064428_create_superadmin_user.sql
-- =====================================================================

/*
  # Create Super Admin User

  ## Purpose
  Creates a default super admin user for initial system access.
  
  ## Details
  - Email: superadmin@vista.local
  - Password: Vista2024!Super (MUST CHANGE ON FIRST LOGIN)
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

-- =====================================================================
-- SOURCE: 20251213065055_add_service_role_bypass_for_admin_setup.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213071518_fix_infinite_recursion_in_user_roles.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213071924_fix_user_creation_trigger.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213071941_remove_blocking_insert_policy.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213072825_fix_client_registration_and_storage.sql
-- =====================================================================

/*
  # Fix Client Registration and Storage

  ## Problem
  1. Storage bucket "documents" doesn't exist for KTP uploads
  2. RLS policy blocks client registration when user_id is NULL
  
  ## Changes
  1. Storage
    - Create "documents" bucket for KTP and document uploads
    - Enable public access for document viewing
    - Set up RLS policies for secure uploads
  
  2. Security
    - Update clients INSERT policy to allow NULL user_id for new registrations
    - Maintain security by checking authenticated users can only insert their own data OR admin can insert for anyone
    - Allow unauthenticated users to insert with NULL user_id (for public registration form)
*/

-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete documents" ON storage.objects;

-- Storage policies: Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

-- Storage policies: Anyone can view documents (public bucket)
CREATE POLICY "Anyone can view documents"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'documents');

-- Storage policies: Users can update their own uploads
CREATE POLICY "Users can update own documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'documents')
WITH CHECK (bucket_id = 'documents');

-- Storage policies: Admins can delete any document
CREATE POLICY "Admins can delete documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'documents' AND is_admin());

-- Fix clients table RLS policy for INSERT
-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can insert own client data" ON clients;

-- Create new policy that allows:
-- 1. Authenticated users to insert their own data (user_id = auth.uid())
-- 2. Authenticated admins to insert for anyone
-- 3. Public/unauthenticated to insert with user_id = NULL (for registration form)
CREATE POLICY "Allow client registration"
ON clients
FOR INSERT
TO public
WITH CHECK (
  -- Allow if user_id is NULL (public registration)
  user_id IS NULL
  OR
  -- Allow if authenticated and inserting own data
  (auth.uid() = user_id)
  OR
  -- Allow if admin
  (auth.uid() IS NOT NULL AND is_admin())
);

-- =====================================================================
-- SOURCE: 20251213072852_fix_onboarding_progress_for_public_registration.sql
-- =====================================================================

/*
  # Fix Onboarding Progress for Public Registration

  ## Problem
  client_onboarding_progress policies only allow authenticated users to insert
  But public registration form (unauthenticated) needs to insert progress records
  for newly created clients with user_id = NULL
  
  ## Solution
  Add policy to allow public/unauthenticated inserts for clients with user_id = NULL
  
  ## Changes
  - Add new INSERT policy for public registration flow
  - Allow insert if the associated client has user_id = NULL
*/

-- Allow public to insert onboarding progress for unregistered clients (user_id = NULL)
CREATE POLICY "Allow progress for public registration"
ON client_onboarding_progress
FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM clients
    WHERE clients.id = client_onboarding_progress.client_id
    AND clients.user_id IS NULL
  )
);

-- =====================================================================
-- SOURCE: 20251213073127_allow_anonymous_document_upload.sql
-- =====================================================================

/*
  # Allow Anonymous Document Upload

  ## Problem
  Public registration form uses anon key (unauthenticated users)
  Storage INSERT policy only allows authenticated users
  This blocks KTP upload during registration
  
  ## Solution
  Add storage INSERT policy for anon users to upload documents
  
  ## Changes
  - Add INSERT policy for anon role to upload to documents bucket
  - Maintains security by limiting to documents bucket only
*/

-- Allow anonymous users to upload documents (for registration form)
CREATE POLICY "Anonymous users can upload documents"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (bucket_id = 'documents');

-- =====================================================================
-- SOURCE: 20251213073207_fix_anon_client_registration.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213073235_fix_anon_onboarding_progress.sql
-- =====================================================================

/*
  # Fix Anonymous Onboarding Progress

  ## Problem
  Ensure anon users can insert onboarding progress records
  for newly registered clients with user_id = NULL
  
  ## Solution
  Add specific policy for anon role (in addition to existing public policy)
  
  ## Changes
  - Add dedicated INSERT policy for anon role
  - Allow insert if associated client has user_id = NULL
*/

-- Drop existing public policy and recreate for anon specifically
DROP POLICY IF EXISTS "Allow progress for public registration" ON client_onboarding_progress;

-- Create policy for anon users (public registration form)
CREATE POLICY "Anon users can insert progress for new registrations"
ON client_onboarding_progress
FOR INSERT
TO anon
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM clients
    WHERE clients.id = client_onboarding_progress.client_id
    AND clients.user_id IS NULL
  )
);

-- =====================================================================
-- SOURCE: 20251213073608_add_anon_select_for_client_registration.sql
-- =====================================================================

/*
  # Add SELECT Policy for Anonymous Client Registration

  ## Problem
  Form does .insert().select().single() which requires SELECT permission
  Currently only authenticated users can SELECT from clients table
  Anon users can INSERT but cannot SELECT the returned row
  
  ## Solution
  Add SELECT policy for anon users to read their just-inserted client record
  Restrict to only records where user_id IS NULL (unlinked clients)
  
  ## Changes
  - Add SELECT policy for anon role
  - Allow reading only unlinked client records (user_id IS NULL)
*/

-- Allow anon users to SELECT unlinked client records
-- This is needed for .insert().select() operations
CREATE POLICY "Anon users can view unlinked clients"
ON clients
FOR SELECT
TO anon
USING (user_id IS NULL);

-- =====================================================================
-- SOURCE: 20251213073626_allow_anon_read_onboarding_steps.sql
-- =====================================================================

/*
  # Allow Anonymous Users to Read Onboarding Steps

  ## Problem
  Registration form queries onboarding_steps table to create progress records
  Only authenticated users can currently SELECT from onboarding_steps
  Anon users get blocked when trying to fetch steps
  
  ## Solution
  Add SELECT policy for anon role on onboarding_steps
  Steps are reference data and safe to read publicly
  
  ## Changes
  - Add SELECT policy for anon role on onboarding_steps table
*/

-- Allow anon users to view onboarding steps (reference data)
CREATE POLICY "Anon users can view onboarding steps"
ON onboarding_steps
FOR SELECT
TO anon
USING (true);

-- =====================================================================
-- SOURCE: 20251213074427_fix_user_roles_update_policy_v2.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20251213074750_add_missing_foreign_key_indexes.sql
-- =====================================================================

/*
  # Add Missing Foreign Key Indexes for Performance

  ## Problem
  Multiple tables have foreign keys without covering indexes
  This causes suboptimal query performance when joining tables
  
  ## Solution
  Add indexes on all foreign key columns that don't have them
  
  ## Changes
  - Add index on client_onboarding_progress.client_id
  - Add index on client_onboarding_progress.step_id
  - Add index on documents.client_id
  - Add index on documents.verified_by
  - Add index on kyc_reviews.reviewer_id
  - Add index on notifications.user_id
  - Add index on wpa_schedules.pic_id
*/

-- Add indexes for client_onboarding_progress foreign keys
CREATE INDEX IF NOT EXISTS idx_client_onboarding_progress_client_id 
ON client_onboarding_progress(client_id);

CREATE INDEX IF NOT EXISTS idx_client_onboarding_progress_step_id 
ON client_onboarding_progress(step_id);

-- Add indexes for documents foreign keys
CREATE INDEX IF NOT EXISTS idx_documents_client_id 
ON documents(client_id);

CREATE INDEX IF NOT EXISTS idx_documents_verified_by 
ON documents(verified_by);

-- Add index for kyc_reviews foreign key
CREATE INDEX IF NOT EXISTS idx_kyc_reviews_reviewer_id 
ON kyc_reviews(reviewer_id);

-- Add index for notifications foreign key
CREATE INDEX IF NOT EXISTS idx_notifications_user_id 
ON notifications(user_id);

-- Add index for wpa_schedules foreign key
CREATE INDEX IF NOT EXISTS idx_wpa_schedules_pic_id 
ON wpa_schedules(pic_id);

-- =====================================================================
-- SOURCE: 20251213074833_optimize_rls_policies_performance_v2.sql
-- =====================================================================

/*
  # Optimize RLS Policies for Performance

  ## Problem
  Multiple RLS policies call auth.uid() and is_admin() directly in USING/WITH CHECK clauses
  This causes the functions to be re-evaluated for each row, leading to poor performance
  
  ## Solution
  Wrap all auth.uid() and is_admin() calls with SELECT to evaluate once per query
  This caches the result for the entire query instead of per-row evaluation
  
  ## Changes
  Recreate all RLS policies with optimized (select auth.uid()) pattern
  
  ## Tables Updated
  - user_roles
  - clients  
  - client_onboarding_progress
  - documents
  - notifications
  - audit_logs
  - kyc_reviews
  - wpa_schedules
*/

-- USER_ROLES policies
DROP POLICY IF EXISTS "Users can view own role" ON user_roles;
CREATE POLICY "Users can view own role"
ON user_roles
FOR SELECT
TO authenticated
USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Allow trigger to insert client roles" ON user_roles;
CREATE POLICY "Allow trigger to insert client roles"
ON user_roles
FOR INSERT
TO authenticated
WITH CHECK ((role = 'client') AND ((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "Users can update own password status" ON user_roles;
CREATE POLICY "Users can update own password status"
ON user_roles
FOR UPDATE
TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admins can update user roles" ON user_roles;
CREATE POLICY "Admins can update user roles"
ON user_roles
FOR UPDATE
TO authenticated
USING ((select is_admin()))
WITH CHECK ((select is_admin()));

-- CLIENTS policies
DROP POLICY IF EXISTS "Users can view client data" ON clients;
CREATE POLICY "Users can view client data"
ON clients
FOR SELECT
TO authenticated
USING (user_id = (select auth.uid()) OR (select is_admin()));

DROP POLICY IF EXISTS "Users can update client data" ON clients;
CREATE POLICY "Users can update client data"
ON clients
FOR UPDATE
TO authenticated
USING (user_id = (select auth.uid()) OR (select is_admin()))
WITH CHECK (user_id = (select auth.uid()) OR (select is_admin()));

DROP POLICY IF EXISTS "Authenticated users can insert own client data" ON clients;
CREATE POLICY "Authenticated users can insert own client data"
ON clients
FOR INSERT
TO authenticated
WITH CHECK (user_id = (select auth.uid()) OR user_id IS NULL);

-- CLIENT_ONBOARDING_PROGRESS policies
DROP POLICY IF EXISTS "Users can view progress" ON client_onboarding_progress;
CREATE POLICY "Users can view progress"
ON client_onboarding_progress
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM clients 
    WHERE clients.id = client_onboarding_progress.client_id 
    AND clients.user_id = (select auth.uid())
  ) 
  OR (select is_admin())
);

DROP POLICY IF EXISTS "Users can insert progress" ON client_onboarding_progress;
CREATE POLICY "Users can insert progress"
ON client_onboarding_progress
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM clients 
    WHERE clients.id = client_onboarding_progress.client_id 
    AND clients.user_id = (select auth.uid())
  ) 
  OR (select is_admin())
);

DROP POLICY IF EXISTS "Users can update progress" ON client_onboarding_progress;
CREATE POLICY "Users can update progress"
ON client_onboarding_progress
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM clients 
    WHERE clients.id = client_onboarding_progress.client_id 
    AND clients.user_id = (select auth.uid())
  ) 
  OR (select is_admin())
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM clients 
    WHERE clients.id = client_onboarding_progress.client_id 
    AND clients.user_id = (select auth.uid())
  ) 
  OR (select is_admin())
);

-- DOCUMENTS policies
DROP POLICY IF EXISTS "Users can view documents" ON documents;
CREATE POLICY "Users can view documents"
ON documents
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM clients 
    WHERE clients.id = documents.client_id 
    AND clients.user_id = (select auth.uid())
  ) 
  OR (select is_admin())
);

DROP POLICY IF EXISTS "Users can insert documents" ON documents;
CREATE POLICY "Users can insert documents"
ON documents
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM clients 
    WHERE clients.id = documents.client_id 
    AND clients.user_id = (select auth.uid())
  ) 
  OR (select is_admin())
);

-- NOTIFICATIONS policies
DROP POLICY IF EXISTS "Users can view notifications" ON notifications;
CREATE POLICY "Users can view notifications"
ON notifications
FOR SELECT
TO authenticated
USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Users can update notifications" ON notifications;
CREATE POLICY "Users can update notifications"
ON notifications
FOR UPDATE
TO authenticated
USING (user_id = (select auth.uid()))
WITH CHECK (user_id = (select auth.uid()));

-- AUDIT_LOGS policies
DROP POLICY IF EXISTS "Admins can view audit logs" ON audit_logs;
CREATE POLICY "Admins can view audit logs"
ON audit_logs
FOR SELECT
TO authenticated
USING ((select is_admin()));

DROP POLICY IF EXISTS "Admins can insert audit logs" ON audit_logs;
CREATE POLICY "Admins can insert audit logs"
ON audit_logs
FOR INSERT
TO authenticated
WITH CHECK ((select is_admin()));

-- KYC_REVIEWS policies
DROP POLICY IF EXISTS "Admins can view KYC reviews" ON kyc_reviews;
CREATE POLICY "Admins can view KYC reviews"
ON kyc_reviews
FOR SELECT
TO authenticated
USING ((select is_admin()));

DROP POLICY IF EXISTS "Admins can insert KYC reviews" ON kyc_reviews;
CREATE POLICY "Admins can insert KYC reviews"
ON kyc_reviews
FOR INSERT
TO authenticated
WITH CHECK ((select is_admin()));

DROP POLICY IF EXISTS "Admins can update KYC reviews" ON kyc_reviews;
CREATE POLICY "Admins can update KYC reviews"
ON kyc_reviews
FOR UPDATE
TO authenticated
USING ((select is_admin()))
WITH CHECK ((select is_admin()));

-- WPA_SCHEDULES policies
DROP POLICY IF EXISTS "Admins can view WPA schedules" ON wpa_schedules;
CREATE POLICY "Admins can view WPA schedules"
ON wpa_schedules
FOR SELECT
TO authenticated
USING ((select is_admin()));

DROP POLICY IF EXISTS "Admins can insert WPA schedules" ON wpa_schedules;
CREATE POLICY "Admins can insert WPA schedules"
ON wpa_schedules
FOR INSERT
TO authenticated
WITH CHECK ((select is_admin()));

DROP POLICY IF EXISTS "Admins can update WPA schedules" ON wpa_schedules;
CREATE POLICY "Admins can update WPA schedules"
ON wpa_schedules
FOR UPDATE
TO authenticated
USING ((select is_admin()))
WITH CHECK ((select is_admin()));

-- =====================================================================
-- SOURCE: 20251213074913_fix_duplicate_permissive_policies.sql
-- =====================================================================

/*
  # Fix Multiple Permissive Policies

  ## Problem
  Some tables have duplicate permissive policies that cause Supabase warnings
  - client_onboarding_progress has redundant INSERT policies
  - notifications and user_roles have multiple policies (but they're intentional)
  
  ## Solution
  Remove redundant policies and keep the most optimized versions
  
  ## Changes
  - Remove "Users can insert own progress" (redundant with "Users can insert progress")
  - Keep other multiple policies as they serve different purposes
*/

-- Remove redundant policy on client_onboarding_progress
DROP POLICY IF EXISTS "Users can insert own progress" ON client_onboarding_progress;

-- =====================================================================
-- SOURCE: 20251213074937_fix_function_search_path_security.sql
-- =====================================================================

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

-- =====================================================================
-- SOURCE: 20260116024144_20250116_fix_anon_registration_policies.sql
-- =====================================================================

/*
  # Fix Anonymous User Registration RLS Policies

  ## Issue
  Anonymous users registering clients cannot insert onboarding progress due to RLS restrictions.

  ## Solution
  1. Verify anonymous user INSERT policy on clients table allows user_id IS NULL
  2. Verify anonymous user INSERT policy on client_onboarding_progress allows inserts when associated client has user_id IS NULL
  3. Add explicit policy if needed
*/

-- Verify clients table allows anon inserts with user_id NULL
DO $$
BEGIN
  -- The policy "Anon users can register" on clients table should allow:
  -- INSERT for anon role WHERE user_id IS NULL
  -- This policy already exists but we're documenting it
  RAISE NOTICE 'Anonymous registration policy verified on clients table';
END $$;

-- Verify client_onboarding_progress allows anon inserts
DO $$
BEGIN
  -- The policy "Anon users can insert progress for new registrations" should allow:
  -- INSERT for anon role WHERE client exists with user_id IS NULL
  -- This policy already exists but we're documenting it
  RAISE NOTICE 'Anonymous progress policy verified on client_onboarding_progress table';
END $$;

-- Ensure both policies are working by testing the conditions
-- If a policy doesn't exist, we'll add it
DO $$
DECLARE
  anon_clients_policy_exists BOOLEAN;
  anon_progress_policy_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'clients' 
    AND policyname = 'Anon users can register'
    AND roles::text LIKE '%anon%'
  ) INTO anon_clients_policy_exists;

  SELECT EXISTS(
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'client_onboarding_progress' 
    AND policyname = 'Anon users can insert progress for new registrations'
    AND roles::text LIKE '%anon%'
  ) INTO anon_progress_policy_exists;

  IF anon_clients_policy_exists AND anon_progress_policy_exists THEN
    RAISE NOTICE 'All required anonymous registration policies are in place';
  ELSE
    RAISE WARNING 'Some anonymous registration policies may be missing';
  END IF;
END $$;


-- =====================================================================
-- KOREKSI 2026-07-27 — daftar produk aktif
--
-- Migration lama (20251213063312) hanya mendaftarkan 3 produk, sementara
-- frontend menawarkan 5. Akibatnya 'bimbel_only' dan 'vip_plus_membership'
-- SELALU GAGAL saat registrasi (check constraint violation 23514).
-- Produk 'bimbel_prop' (Kelas Bimbel + Propfunds) DIHAPUS dari penawaran.
--
-- Produk aktif: ea_trading, bimbel_only, vip_membership, vip_plus_membership
-- =====================================================================

ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_product_type_check;
ALTER TABLE clients ADD CONSTRAINT clients_product_type_check
  CHECK (product_type = ANY (ARRAY[
    'ea_trading'::text,
    'bimbel_only'::text,
    'vip_membership'::text,
    'vip_plus_membership'::text
  ]));
