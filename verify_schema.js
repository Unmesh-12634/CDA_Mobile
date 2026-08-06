require('dotenv').config();
const supabase = require('./supabaseClient');

const expectedTables = [
  'users',
  'user_auth',
  'companies',
  'jobs',
  'saved_jobs',
  'job_applications',
  'reels',
  'saved_reels',
  'daily_questions',
  'quiz_attempts',
  'user_settings',
  'ai_interview_reports',
  'user_progress'
];

async function verifyAllTables() {
  console.log('=== Verifying New Schema Tables in Supabase ===\n');

  for (const table of expectedTables) {
    const { data, error } = await supabase.from(table).select('*').limit(1);
    if (error) {
      console.log(`❌ Table '${table}': NOT FOUND / ${error.message}`);
    } else {
      console.log(`✅ Table '${table}': ACCESSIBLE (${data.length} rows sample)`);
    }
  }
}

verifyAllTables().catch(console.error);
