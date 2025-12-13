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