# Quick Deploy to Vercel - Step by Step

## Method 1: Deploy via Vercel Dashboard (Paling Mudah)

### Step 1: Push ke Git Repository

```bash
# Initialize git (jika belum)
git init

# Add semua file
git add .

# Commit
git commit -m "Ready for deployment"

# Connect ke remote repository (GitHub/GitLab)
git remote add origin https://github.com/username/vista-onboarding.git

# Push
git push -u origin main
```

### Step 2: Import ke Vercel

1. Buka https://vercel.com dan login
2. Klik **"Add New Project"**
3. Pilih **"Import Git Repository"**
4. Pilih repository yang baru Anda push
5. Vercel akan otomatis detect **Vite** framework

### Step 3: Configure Environment Variables

Di halaman konfigurasi project, tambahkan:

**Environment Variables:**
```
VITE_SUPABASE_URL=https://qkjcycsmnbihgyjqhmzz.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFramN5Y3NtbmJpaGd5anFobXp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MDYwODQsImV4cCI6MjA4MTE4MjA4NH0.SAGZsFQRLN0XfXI6cH9_iCm90xGtdi0imElNLWHNH7s
```

### Step 4: Deploy

1. Klik **"Deploy"**
2. Tunggu proses build (2-3 menit)
3. Selesai! Anda akan dapat URL deployment

---

## Method 2: Deploy via Vercel CLI

### Install Vercel CLI

```bash
npm install -g vercel
```

### Login

```bash
vercel login
```

### Deploy

```bash
# Deploy ke preview
vercel

# Deploy ke production
vercel --prod
```

### Set Environment Variables via CLI

```bash
vercel env add VITE_SUPABASE_URL
# Paste value: https://qkjcycsmnbihgyjqhmzz.supabase.co

vercel env add VITE_SUPABASE_ANON_KEY
# Paste value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Verification Checklist

Setelah deploy, test URL Anda:

### Test Client Portal
- [ ] Buka `https://your-app.vercel.app/`
- [ ] Form wizard bisa dibuka
- [ ] Bisa pilih produk
- [ ] Bisa upload KTP
- [ ] Bisa submit form

### Test Admin Portal
- [ ] Buka `https://your-app.vercel.app/admin`
- [ ] Halaman login admin muncul
- [ ] Bisa login dengan admin credentials
- [ ] Dashboard muncul dengan data
- [ ] Bisa review client

---

## Troubleshooting

### Build Gagal: "environment variables not found"
**Solusi**: Tambahkan environment variables di Vercel Dashboard → Settings → Environment Variables

### 404 Error di /admin route
**Solusi**: Pastikan file `vercel.json` ada di root project dan sudah di-commit

### "Failed to load data from Supabase"
**Solusi**:
1. Check environment variables sudah benar
2. Verify Supabase URL dan anon key
3. Check database migrations sudah dijalankan

### CORS Error
**Solusi**: Supabase secara default sudah allow all origins. Jika masih error, check Supabase Dashboard → Settings → API

---

## Custom Domain

Untuk menggunakan custom domain (misalnya: onboarding.govista.co.id):

1. Buka Vercel Dashboard → Project Settings → Domains
2. Klik **"Add Domain"**
3. Masukkan domain Anda
4. Follow instruksi DNS configuration:
   - **Type**: CNAME
   - **Name**: onboarding (or @)
   - **Value**: cname.vercel-dns.com

5. Tunggu DNS propagation (5-30 menit)
6. Done!

---

## Update Deployment

Setiap kali Anda push ke Git repository, Vercel akan otomatis:
1. Detect perubahan
2. Build ulang
3. Deploy versi baru
4. Generate preview URL

**Auto-deployment** aktif by default untuk:
- Production branch (main/master)
- Pull requests (preview deployment)

---

## URLs After Deployment

- **Production**: `https://your-project.vercel.app`
- **Client Portal**: `https://your-project.vercel.app/`
- **Admin Portal**: `https://your-project.vercel.app/admin`

---

## Need Help?

- Vercel Docs: https://vercel.com/docs
- Vercel Support: https://vercel.com/support
- Full Guide: See `DEPLOYMENT_GUIDE.md`
