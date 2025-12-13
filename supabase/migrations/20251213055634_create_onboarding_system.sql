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