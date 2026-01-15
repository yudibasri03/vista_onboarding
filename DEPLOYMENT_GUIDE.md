# Deployment Guide - Vista Client Onboarding Portal

## Deploy ke Vercel

### 1. Persiapan

Pastikan semua dependencies sudah terinstall:
```bash
npm install
```

### 2. Build Lokal (Opsional - untuk testing)

Test build aplikasi:
```bash
npm run build
```

### 3. Deploy ke Vercel

#### Opsi A: Deploy via Vercel CLI

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Login ke Vercel:
```bash
vercel login
```

3. Deploy:
```bash
vercel
```

4. Untuk production:
```bash
vercel --prod
```

#### Opsi B: Deploy via Vercel Dashboard (Recommended)

1. **Push ke GitHub/GitLab/Bitbucket** (jika belum)
   - Create repository baru
   - Push kode ke repository

2. **Import ke Vercel**
   - Buka https://vercel.com
   - Klik "Add New Project"
   - Import repository Anda
   - Vercel akan otomatis detect Vite framework

3. **Configure Project**
   - Framework Preset: **Vite**
   - Build Command: `npm run build`
   - Output Directory: `dist`
   - Install Command: `npm install`

### 4. Environment Variables (PENTING!)

Di Vercel Dashboard, tambahkan environment variables:

1. Buka Project Settings → Environment Variables
2. Tambahkan variables berikut:

```
VITE_SUPABASE_URL=https://qkjcycsmnbihgyjqhmzz.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFramN5Y3NtbmJpaGd5anFibXp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MDYwODQsImV4cCI6MjA4MTE4MjA4NH0.SAGZsFQRLN0XfXI6cH9_iCm90xGtdi0imElNLWHNH7s
```

**PENTING**: Pastikan environment variables ditambahkan untuk semua environment (Production, Preview, Development)

### 5. Domain & URL

Setelah deploy berhasil, Anda akan mendapat URL seperti:
- `https://your-project-name.vercel.app`

#### Akses Aplikasi:
- **Client Portal**: `https://your-project-name.vercel.app/`
- **Admin Portal**: `https://your-project-name.vercel.app/admin`

### 6. Custom Domain (Opsional)

Di Vercel Dashboard:
1. Buka Project Settings → Domains
2. Add custom domain (misalnya: `onboarding.govista.co.id`)
3. Follow DNS configuration instructions

### 7. Testing Deployment

1. **Test Client Portal**:
   - Buka URL utama
   - Isi form registrasi
   - Upload KTP
   - Submit form

2. **Test Admin Portal**:
   - Buka `/admin`
   - Login dengan admin credentials
   - Check dashboard dan review clients

### 8. Monitoring

- **Vercel Analytics**: Aktifkan di Project Settings
- **Real-time Logs**: Check di Vercel Dashboard → Deployments → Logs

## Troubleshooting

### Build Gagal

```bash
# Test build lokal
npm run build

# Check error di console
```

### Environment Variables Tidak Terdeteksi

- Pastikan prefix `VITE_` digunakan untuk semua environment variables
- Redeploy setelah menambahkan environment variables

### Routing 404 di /admin

- Pastikan `vercel.json` sudah ada dan di-commit ke repository
- Vercel otomatis akan handle SPA routing

### Supabase Connection Error

- Verify environment variables sudah benar
- Check Supabase project masih aktif
- Verify anon key belum expired

## Post-Deployment Checklist

✅ Environment variables configured
✅ Client portal accessible
✅ Admin portal accessible at `/admin`
✅ Form submission works
✅ File upload works
✅ Admin login works
✅ Dashboard loads data from Supabase
✅ Custom domain configured (if applicable)

## Security Notes

- ✅ Anon key is safe to expose (read-only access)
- ✅ RLS policies protect all data
- ✅ Admin access controlled by user_roles table
- ✅ KYC documents uploaded to Supabase Storage

## Support

Untuk bantuan lebih lanjut:
- Vercel Docs: https://vercel.com/docs
- Supabase Docs: https://supabase.com/docs
