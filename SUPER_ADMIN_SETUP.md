# Setup Super Admin

## Metode 1: Via Supabase Dashboard (Recommended)

1. Buka **Supabase Dashboard** → **Authentication** → **Users**
2. Klik **Add User** → **Create new user**
3. Isi data berikut:
   - **Email**: `superadmin@vista.local`
   - **Password**: `Vista2024!Admin` (password sementara)
   - **Auto Confirm User**: ✅ Centang

4. Setelah user dibuat, copy **User ID** nya

5. Buka **SQL Editor** di Supabase Dashboard dan jalankan query berikut:

```sql
-- Ganti <USER_ID> dengan ID user yang baru dibuat
INSERT INTO user_roles (user_id, role, must_change_password)
VALUES ('<USER_ID>', 'admin', true);
```

6. Sekarang Anda bisa login dengan:
   - **Email**: `superadmin@vista.local`
   - **Password**: `Vista2024!Admin`

7. Setelah login pertama kali, sistem akan **memaksa Anda mengganti password**

---

## Metode 2: Via SQL Direct

Jika Anda ingin password yang lebih aman dari awal, jalankan script berikut di **SQL Editor**:

```sql
-- Buat user baru dengan password aman
-- Password: Generate sendiri yang kuat, misal: MyS3cur3P@ssw0rd!2024

-- 1. User akan dibuat via Dashboard (ikuti langkah di Metode 1)
-- 2. Setelah dapat user_id, jalankan:

INSERT INTO user_roles (user_id, role, must_change_password)
VALUES ('<USER_ID_DARI_DASHBOARD>', 'admin', true);
```

---

## Keamanan

✅ Password wajib diganti pada login pertama
✅ Modal ganti password tidak bisa dilewati
✅ Validasi password ketat (min 8 karakter, huruf besar/kecil, angka, simbol)

---

## Troubleshooting

**Q: Edge function gagal create user?**
A: Gunakan metode manual via Dashboard (Metode 1). Edge function memerlukan konfigurasi tambahan yang bisa berbeda per project.

**Q: Lupa password super admin?**
A: Reset via Supabase Dashboard → Authentication → Users → pilih user → Reset password

---

## Kredensial Default (Metode 1)

```
Email: superadmin@vista.local
Password: Vista2024!Admin
```

**⚠️ PENTING**: Password ini akan diminta diganti saat login pertama!
