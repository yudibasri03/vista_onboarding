# Self-Host Supabase untuk Vista CRM

Panduan memindahkan backend + database ke **Supabase yang kamu host sendiri** di VPS,
lepas total dari free tier supabase.com. **Frontend tetap di Vercel.**

Kode aplikasi **tidak berubah** — kita cuma mengganti `VITE_SUPABASE_URL` &
`VITE_SUPABASE_ANON_KEY` supaya menunjuk ke server sendiri.

Isi folder ini:
| File | Fungsi |
|------|--------|
| `schema.sql` | Seluruh skema DB (9 tabel + RLS + storage), gabungan semua migration, urut |
| `generate-keys.mjs` | Generate JWT_SECRET, password, ANON_KEY, SERVICE_ROLE_KEY |
| `Caddyfile` | Reverse proxy + HTTPS otomatis (Let's Encrypt) |
| `backup.sh` | Backup harian database (cron) |
| `frontend.env.example` | Nilai env untuk Vercel |

---

## Prasyarat

1. **VPS** Ubuntu 22.04/24.04, **minimal 2 GB RAM** (disarankan 4 GB). Contoh murah: Hetzner CX22, Contabo, DigitalOcean.
2. **Domain/subdomain** untuk API, mis. `api.namamu.com`, dengan **A record → IP VPS**.
   (Wajib: frontend Vercel yang HTTPS harus memanggil API yang HTTPS juga.)

---

## Langkah 1 — Generate secret (di komputermu)

```bash
node self-host/generate-keys.mjs
```

Simpan output-nya. Kamu butuh: `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANON_KEY`,
`SERVICE_ROLE_KEY`, `DASHBOARD_PASSWORD`, dan `ANON_KEY` (untuk Vercel nanti).

## Langkah 2 — Install Docker di VPS

```bash
ssh root@IP_VPS
curl -fsSL https://get.docker.com | sh
```

## Langkah 3 — Ambil Supabase docker & konfigurasi

```bash
git clone --depth 1 https://github.com/supabase/supabase
cd supabase/docker
cp .env.example .env
nano .env
```

Ubah/isi nilai berikut di `.env` (sisanya biarkan default):

```ini
# --- dari generate-keys.mjs ---
POSTGRES_PASSWORD=<hasil generate>
JWT_SECRET=<hasil generate>
ANON_KEY=<hasil generate>
SERVICE_ROLE_KEY=<hasil generate>
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=<hasil generate>

# --- URL publik (ganti dengan domain-mu) ---
API_EXTERNAL_URL=https://api.namamu.com
SUPABASE_PUBLIC_URL=https://api.namamu.com
SITE_URL=https://nama-crm-mu.vercel.app        # URL frontend di Vercel

# --- email: karena belum pasang SMTP, auto-confirm user baru ---
ENABLE_EMAIL_AUTOCONFIRM=true
```

> Nanti kalau mau kirim email verifikasi/reset password sungguhan, isi `SMTP_*`
> dan set `ENABLE_EMAIL_AUTOCONFIRM=false`.

## Langkah 4 — Jalankan Supabase

```bash
docker compose pull
docker compose up -d
docker compose ps      # semua service harus "healthy"/"running"
```

## Langkah 5 — HTTPS dengan Caddy

Install Caddy & pakai `Caddyfile` dari folder ini (ganti `api.namamu.com` dengan domain-mu):

```bash
# install caddy (Ubuntu)
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy

# taruh Caddyfile lalu:
caddy start
```

Cek: buka `https://api.namamu.com` → harus muncul login Supabase Studio
(user/pass = `DASHBOARD_USERNAME`/`DASHBOARD_PASSWORD`).

## Langkah 6 — Apply skema database

Salin `schema.sql` ke VPS (mis. `scp self-host/schema.sql root@IP_VPS:/root/`), lalu:

```bash
cd /root/supabase/docker
docker compose exec -T db psql -U postgres -d postgres < /root/schema.sql
```

Verifikasi tabel terbentuk:

```bash
docker compose exec -T db psql -U postgres -d postgres -c "\dt public.*"
```

Harus muncul: `clients`, `onboarding_steps`, `client_onboarding_progress`,
`documents`, `notifications`, `user_roles`, `audit_logs`, `kyc_reviews`, `wpa_schedules`.

## Langkah 7 — Buat user admin

Buka Studio (`https://api.namamu.com`) → **Authentication → Add user** →
isi email + password admin, centang auto-confirm. Lalu di **SQL Editor**:

```sql
insert into user_roles (user_id, role, must_change_password)
select id, 'admin', false from auth.users where email = 'admin@perusahaanmu.com'
on conflict (user_id) do update set role = 'admin';
```

## Langkah 8 — Arahkan frontend ke server sendiri

Di **Vercel → Project Settings → Environment Variables**:

```
VITE_SUPABASE_URL      = https://api.namamu.com
VITE_SUPABASE_ANON_KEY = <ANON_KEY dari langkah 1>
```

Lalu **Redeploy**. (Untuk dev lokal, samakan di file `.env` root project.)

Selesai — CRM sekarang jalan sepenuhnya di server sendiri. ✅

## Langkah 9 — Backup otomatis (WAJIB)

```bash
# edit path di backup.sh, lalu pasang cron:
crontab -e
# tambahkan:
0 2 * * * /root/self-host/backup.sh >> /var/log/supabase-backup.log 2>&1
```

---

## Checklist verifikasi

- [ ] `https://api.namamu.com/rest/v1/` merespons (bukan error koneksi)
- [ ] Buka form registrasi di frontend → submit → data masuk ke tabel `clients` (cek di Studio)
- [ ] Upload KTP berhasil (cek Studio → Storage → bucket `documents`)
- [ ] Login admin di `/admin` → dashboard tampil
- [ ] `backup.sh` menghasilkan file `.sql.gz`

## Catatan keamanan

- Jangan pernah expose `SERVICE_ROLE_KEY` ke frontend — hanya `ANON_KEY` yang boleh di Vercel.
- Aktifkan firewall: hanya buka port `22, 80, 443`. Port 8000 cukup diakses lewat Caddy (localhost).
  ```bash
  ufw allow 22 && ufw allow 80 && ufw allow 443 && ufw enable
  ```
- Backup rutin & sesekali salin ke storage lain (S3/Backblaze/lokal).
