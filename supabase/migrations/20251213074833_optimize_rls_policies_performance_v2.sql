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