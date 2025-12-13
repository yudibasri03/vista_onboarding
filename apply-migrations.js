const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://qkjcycsmnbihgyjqhmzz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFramN5Y3NtbmJpaGd5anFobXp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MDYwODQsImV4cCI6MjA4MTE4MjA4NH0.SAGZsFQRLN0XfXI6cH9_iCm90xGtdi0imElNLWHNH7s';

const supabase = createClient(supabaseUrl, supabaseKey);

async function applyMigrations() {
  const sql = fs.readFileSync('/tmp/combined_migration.sql', 'utf8');

  console.log('Applying migrations...');
  console.log('SQL size:', sql.length, 'bytes');

  try {
    const { data, error } = await supabase.rpc('exec', { sql });

    if (error) {
      console.error('Error:', error);
      process.exit(1);
    }

    console.log('Migrations applied successfully!');
    console.log('Result:', data);
  } catch (err) {
    console.error('Exception:', err.message);
    process.exit(1);
  }
}

applyMigrations();
