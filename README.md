# Vista Client Onboarding Portal

Platform registrasi resmi untuk produk investasi dan trading Vista. Sistem onboarding client lengkap dengan verifikasi KYC dan admin dashboard.

## 🚀 Quick Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone)

### Deployment Steps

1. **Push to GitHub/GitLab**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Deploy to Vercel**
   - Visit [vercel.com](https://vercel.com)
   - Import your repository
   - Add environment variables:
     - `VITE_SUPABASE_URL`
     - `VITE_SUPABASE_ANON_KEY`
   - Deploy!

3. **Access Your App**
   - Client Portal: `https://your-app.vercel.app/`
   - Admin Portal: `https://your-app.vercel.app/admin`

📖 **[Full Deployment Guide](./DEPLOYMENT_GUIDE.md)**

## 🎯 Features

### Client Portal
- Multi-step onboarding wizard
- KYC document upload (KTP)
- Product selection (EA Trading, Bimbel + Prop, VIP Membership)
- Risk profile configuration
- Real-time validation

### Admin Portal
- Comprehensive dashboard with statistics
- Client review and approval system
- KYC document verification
- Audit trail tracking
- CSV export functionality
- Advanced filtering and search

## 🛠️ Tech Stack

- **Frontend**: React 18 + TypeScript + Vite
- **Styling**: Tailwind CSS
- **Icons**: Lucide React
- **Backend**: Supabase (Database + Auth + Storage)
- **Deployment**: Vercel

## 📦 Local Development

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Setup Environment Variables**
   Create `.env` file:
   ```
   VITE_SUPABASE_URL=your_supabase_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Run Development Server**
   ```bash
   npm run dev
   ```

4. **Build for Production**
   ```bash
   npm run build
   ```

## 🗄️ Database Setup

See [DATABASE_SETUP.md](./DATABASE_SETUP.md) for complete database migration instructions.

## 👤 Admin Setup

See [SUPER_ADMIN_SETUP.md](./SUPER_ADMIN_SETUP.md) for creating the first admin user.

## 🔐 Security

- Row Level Security (RLS) enabled on all tables
- JWT-based authentication via Supabase
- Secure file uploads to Supabase Storage
- Admin role verification on all sensitive operations

## 📄 License

Internal use only - Vistamaju Penasihat Berjangka
