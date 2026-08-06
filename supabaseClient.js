require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_KEY in environment variables.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConnection() {
  console.log(`Connecting to Supabase project at ${supabaseUrl}...`);
  // Try querying edu_user or any existing table
  const { data, error, count } = await supabase
    .from('edu_user')
    .select('*', { count: 'exact', head: true });

  if (error) {
    console.error('Supabase Query Error:', error.message);
  } else {
    console.log('✅ Connection Successful!');
    console.log(`Table 'edu_user' total rows count: ${count}`);
  }
}

if (require.main === module) {
  testConnection();
}

module.exports = supabase;
