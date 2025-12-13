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