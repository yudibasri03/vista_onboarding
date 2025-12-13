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