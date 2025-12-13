# Database Setup Instructions

Your new Supabase database (`qkjcycsmnbihgyjqhmzz`) needs to have all migrations applied.

## Quick Setup

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/qkjcycsmnbihgyjqhmzz/sql

2. **Execute the Combined Migration**
   - Copy the contents of `/tmp/combined_migration.sql` (or combine all migrations from `supabase/migrations/` folder)
   - Paste into the SQL Editor
   - Click "Run" to execute

## Alternative: Run Migrations One by One

Execute these migration files in order in the Supabase SQL Editor:

1. `20251213055634_create_onboarding_system.sql` - Creates base tables
2. `20251213060253_fix_rls_policies.sql` - Adds missing RLS policies
3. `20251213060546_optimize_security_and_performance_v2.sql` - Adds indexes and optimizes
4. `20251213060842_fix_rls_performance_with_public_helper.sql` - Performance improvements
5. `20251213061746_remove_unused_indexes.sql` - Cleanup
6. `20251213062904_add_admin_role_system.sql` - **CRITICAL**: Adds user_roles table
7. `20251213063312_add_vista_onboarding_fields.sql` - Adds Vista-specific fields
8. `20251213063709_add_audit_trail_system.sql` - Adds audit logging
9. `20251213064209_make_user_id_nullable_in_clients.sql` - Allows direct registration
10. `20251213064428_create_superadmin_user.sql` - Adds password change tracking
11. `20251213065055_add_service_role_bypass_for_admin_setup.sql` - Service role policy

## What Will Be Created

### Tables
- `clients` - Client data with Vista onboarding fields
- `user_roles` - Admin/client role management
- `onboarding_steps` - Onboarding workflow steps
- `client_onboarding_progress` - Progress tracking
- `documents` - Document uploads
- `notifications` - System notifications
- `audit_logs` - Admin action tracking
- `kyc_reviews` - KYC verification tracking
- `wpa_schedules` - WPA call scheduling

### Security
- Row Level Security (RLS) enabled on all tables
- Policies for admin and client access
- Helper functions for auth and performance

## After Migration

Once migrations are applied, you can generate the super admin using either:

### Method 1: Via Dashboard (Recommended)
Follow instructions in `SUPER_ADMIN_SETUP.md`

### Method 2: Via Edge Function
```bash
curl -X POST "https://qkjcycsmnbihgyjqhmzz.supabase.co/functions/v1/setup-admin" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json"
```

## Troubleshooting

**Error: relation "user_roles" does not exist**
- Migrations haven't been applied yet
- Follow the setup steps above

**Error: permission denied**
- Make sure you're using the correct Supabase project
- Check that you have admin access to the dashboard

## Files Location

- Combined migration: `/tmp/combined_migration.sql`
- Individual migrations: `supabase/migrations/*.sql`
- Super admin setup: `SUPER_ADMIN_SETUP.md`
