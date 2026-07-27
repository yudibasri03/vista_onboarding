#!/usr/bin/env node
/*
 * Generate semua secret untuk self-hosted Supabase.
 * Jalankan: node generate-keys.mjs
 *
 * Output: JWT_SECRET, POSTGRES_PASSWORD, ANON_KEY, SERVICE_ROLE_KEY,
 * DASHBOARD_PASSWORD — tinggal salin ke file .env milik Supabase docker.
 *
 * ANON_KEY & SERVICE_ROLE_KEY adalah JWT yang ditandatangani dengan
 * JWT_SECRET, berlaku 10 tahun. Tidak butuh dependency apa pun.
 */
import crypto from 'node:crypto';

const b64url = (input) =>
  Buffer.from(input).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

function signJwt(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const encHeader = b64url(JSON.stringify(header));
  const encPayload = b64url(JSON.stringify(payload));
  const data = `${encHeader}.${encPayload}`;
  const sig = crypto.createHmac('sha256', secret).update(data).digest('base64')
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  return `${data}.${sig}`;
}

const randHex = (bytes) => crypto.randomBytes(bytes).toString('hex');
// password aman tanpa karakter yang bikin ribet di .env / URL
const randPass = (bytes) => crypto.randomBytes(bytes).toString('base64')
  .replace(/[+/=]/g, '').slice(0, bytes);

const JWT_SECRET = randHex(24); // 48 char, > minimum 32
const POSTGRES_PASSWORD = randPass(32);
const DASHBOARD_PASSWORD = randPass(20);

const iat = Math.floor(Date.now() / 1000);
const exp = iat + 60 * 60 * 24 * 365 * 10; // 10 tahun

const ANON_KEY = signJwt({ role: 'anon', iss: 'supabase', iat, exp }, JWT_SECRET);
const SERVICE_ROLE_KEY = signJwt({ role: 'service_role', iss: 'supabase', iat, exp }, JWT_SECRET);

console.log(`
# ============================================================
# Salin nilai-nilai ini ke file .env Supabase docker
# (supabase/docker/.env). SIMPAN BAIK-BAIK & JANGAN commit.
# ============================================================

POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
JWT_SECRET=${JWT_SECRET}
ANON_KEY=${ANON_KEY}
SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}

# Login Supabase Studio (dashboard)
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD}

# ============================================================
# Untuk FRONTEND (Environment Variables di Vercel):
#   VITE_SUPABASE_URL      = https://<domain-api-mu>   (mis. https://api.namamu.com)
#   VITE_SUPABASE_ANON_KEY = ${ANON_KEY}
# ============================================================
`);
