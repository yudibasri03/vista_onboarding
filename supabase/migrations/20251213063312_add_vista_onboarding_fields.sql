/*
  # Add Vista Client Onboarding Fields

  ## Changes
  
  1. Add new columns to clients table:
    - `full_name` - Nama lengkap sesuai KTP
    - `whatsapp` - Nomor WhatsApp
    - `occupation` - Pekerjaan
    - `position` - Jabatan
    - `ktp_url` - URL file KTP
    - `product_type` - Jenis produk (ea_trading, bimbel_prop, vip_membership)
    - `product_config` - Konfigurasi produk (JSONB)
    - `risk_profile` - Profile risiko (aggressive, moderate, conservative)
    - `consent_data_accuracy` - Consent data benar
    - `consent_risk_understanding` - Consent memahami risiko
    - `consent_verification_process` - Consent verifikasi lanjutan
    - `registration_completed_at` - Waktu complete registrasi
  
  2. Notes
    - Existing fields (pic_name, phone) tetap ada untuk backward compatibility
    - product_config menggunakan JSONB untuk fleksibilitas
    - Status clients akan menentukan progress onboarding
*/

-- Add new columns to clients table
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS full_name text,
ADD COLUMN IF NOT EXISTS whatsapp text,
ADD COLUMN IF NOT EXISTS occupation text,
ADD COLUMN IF NOT EXISTS position text,
ADD COLUMN IF NOT EXISTS ktp_url text,
ADD COLUMN IF NOT EXISTS product_type text CHECK (product_type IN ('ea_trading', 'bimbel_prop', 'vip_membership')),
ADD COLUMN IF NOT EXISTS product_config jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS risk_profile text CHECK (risk_profile IN ('aggressive', 'moderate', 'conservative', NULL)),
ADD COLUMN IF NOT EXISTS consent_data_accuracy boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS consent_risk_understanding boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS consent_verification_process boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS registration_completed_at timestamptz;

-- Add index for product type queries
CREATE INDEX IF NOT EXISTS idx_clients_product_type ON clients(product_type);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);

-- Add comments for documentation
COMMENT ON COLUMN clients.full_name IS 'Nama lengkap sesuai KTP';
COMMENT ON COLUMN clients.whatsapp IS 'Nomor WhatsApp untuk komunikasi';
COMMENT ON COLUMN clients.occupation IS 'Pekerjaan klien';
COMMENT ON COLUMN clients.position IS 'Jabatan/posisi klien';
COMMENT ON COLUMN clients.ktp_url IS 'URL file KTP yang diupload';
COMMENT ON COLUMN clients.product_type IS 'Jenis produk: ea_trading, bimbel_prop, vip_membership';
COMMENT ON COLUMN clients.product_config IS 'Konfigurasi produk dalam format JSON';
COMMENT ON COLUMN clients.risk_profile IS 'Profile risiko trading: aggressive, moderate, conservative';
COMMENT ON COLUMN clients.consent_data_accuracy IS 'Consent bahwa data yang diisi benar';
COMMENT ON COLUMN clients.consent_risk_understanding IS 'Consent memahami risiko trading';
COMMENT ON COLUMN clients.consent_verification_process IS 'Consent bersedia mengikuti verifikasi lanjutan';