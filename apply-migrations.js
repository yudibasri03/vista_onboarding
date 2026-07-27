/*
 * Migration helper (Vista Onboarding)
 *
 * CATATAN: versi lama script ini memanggil supabase.rpc('exec', { sql }).
 * Fungsi RPC 'exec' TIDAK ADA di Supabase secara default, dan anon key
 * juga tidak punya hak untuk menjalankan DDL. Jadi migration TIDAK PERNAH
 * benar-benar ter-apply lewat cara itu.
 *
 * Ada 2 cara yang benar untuk apply migration ke database:
 *
 * 1) Supabase CLI (disarankan):
 *      npx supabase link --project-ref qkjcycsmnbihgyjqhmzz
 *      npx supabase db push
 *
 * 2) SQL Editor manual:
 *      Buka Supabase Dashboard > SQL Editor > New query,
 *      lalu paste seluruh isi file combined_migration.sql dan Run.
 *
 * Script di bawah hanya menampilkan ringkasan combined_migration.sql
 * supaya mudah diverifikasi sebelum di-paste. Ia TIDAK mengeksekusi apa pun.
 */

const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'combined_migration.sql');

if (!fs.existsSync(file)) {
  console.error('combined_migration.sql tidak ditemukan di', file);
  process.exit(1);
}

const sql = fs.readFileSync(file, 'utf8');
const tables = (sql.match(/CREATE TABLE/gi) || []).length;
const policies = (sql.match(/CREATE POLICY/gi) || []).length;

console.log('combined_migration.sql ditemukan.');
console.log(`  Ukuran   : ${sql.length} bytes (${sql.split('\n').length} baris)`);
console.log(`  CREATE TABLE  : ${tables}`);
console.log(`  CREATE POLICY : ${policies}`);
console.log('');
console.log('Apply migration dengan salah satu cara:');
console.log('  1) npx supabase link --project-ref qkjcycsmnbihgyjqhmzz && npx supabase db push');
console.log('  2) Paste isi combined_migration.sql ke Supabase SQL Editor lalu Run.');
