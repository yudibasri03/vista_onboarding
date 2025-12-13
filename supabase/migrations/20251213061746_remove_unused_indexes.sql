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