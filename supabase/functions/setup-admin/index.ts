import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

function generateRandomPassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%';
  let password = '';
  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Check if super admin already exists
    const { data: existingAdmin } = await supabase
      .from('user_roles')
      .select('id')
      .eq('role', 'admin')
      .maybeSingle();

    if (existingAdmin) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Super admin already exists. This endpoint can only be used once.',
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    // Generate random password
    const randomPassword = generateRandomPassword();
    const adminEmail = 'superadmin@vista.local';

    // Create admin user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: adminEmail,
      password: randomPassword,
      email_confirm: true,
    });

    if (authError) throw authError;

    // Create admin role entry
    const { error: roleError } = await supabase
      .from('user_roles')
      .insert({
        user_id: authData.user.id,
        role: 'admin',
        must_change_password: true,
      });

    if (roleError) throw roleError;

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Super admin created successfully. SAVE THIS PASSWORD - it will only be shown once!',
        credentials: {
          email: adminEmail,
          password: randomPassword,
          note: 'You MUST change this password on first login',
        },
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  } catch (err: any) {
    console.error('Error setting up admin:', err);
    return new Response(
      JSON.stringify({
        success: false,
        error: err.message,
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }
});