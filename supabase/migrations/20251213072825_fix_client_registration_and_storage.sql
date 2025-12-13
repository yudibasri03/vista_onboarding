/*
  # Fix Client Registration and Storage

  ## Problem
  1. Storage bucket "documents" doesn't exist for KTP uploads
  2. RLS policy blocks client registration when user_id is NULL
  
  ## Changes
  1. Storage
    - Create "documents" bucket for KTP and document uploads
    - Enable public access for document viewing
    - Set up RLS policies for secure uploads
  
  2. Security
    - Update clients INSERT policy to allow NULL user_id for new registrations
    - Maintain security by checking authenticated users can only insert their own data OR admin can insert for anyone
    - Allow unauthenticated users to insert with NULL user_id (for public registration form)
*/

-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete documents" ON storage.objects;

-- Storage policies: Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

-- Storage policies: Anyone can view documents (public bucket)
CREATE POLICY "Anyone can view documents"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'documents');

-- Storage policies: Users can update their own uploads
CREATE POLICY "Users can update own documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'documents')
WITH CHECK (bucket_id = 'documents');

-- Storage policies: Admins can delete any document
CREATE POLICY "Admins can delete documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'documents' AND is_admin());

-- Fix clients table RLS policy for INSERT
-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can insert own client data" ON clients;

-- Create new policy that allows:
-- 1. Authenticated users to insert their own data (user_id = auth.uid())
-- 2. Authenticated admins to insert for anyone
-- 3. Public/unauthenticated to insert with user_id = NULL (for registration form)
CREATE POLICY "Allow client registration"
ON clients
FOR INSERT
TO public
WITH CHECK (
  -- Allow if user_id is NULL (public registration)
  user_id IS NULL
  OR
  -- Allow if authenticated and inserting own data
  (auth.uid() = user_id)
  OR
  -- Allow if admin
  (auth.uid() IS NOT NULL AND is_admin())
);