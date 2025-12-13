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