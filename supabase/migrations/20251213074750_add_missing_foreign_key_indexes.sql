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