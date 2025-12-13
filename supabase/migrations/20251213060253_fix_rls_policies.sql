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