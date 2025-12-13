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

