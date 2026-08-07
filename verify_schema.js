require('dotenv').config();
const supabase = require('./supabaseClient');

const expectedTables = [
  'users',
  'user_auth',
  'companies',
  'jobs',
  'saved_jobs',
  'job_applications',
  'user_job_application',
  'reels',
  'saved_reels',
  'daily_questions',
  'quiz_attempts',
  'user_settings',
  'ai_interview_reports',
  'ai_interview_session',
  'user_weekly_report',
  'user_subscription',
  'user_progress'
];

async function verifyAllTables() {
  console.log('=== Verifying Complete Database Schema in Supabase ===\n');

  for (const table of expectedTables) {
    const { data, error } = await supabase.from(table).select('*').limit(1);
    if (error) {
      console.log(`❌ Table '${table}': NOT FOUND / ${error.message}`);
    } else {
      console.log(`✅ Table '${table}': ACCESSIBLE (${data.length} rows sample)`);
    }
  }

  console.log('\n--- Checking Extended User Profile Columns ---');
  const { data: userData, error: userError } = await supabase
    .from('users')
    .select('target_annual_package, target_role, experience_years, github_url, linkedin_url, portfolio_url, resume_url')
    .limit(1);

  if (userError) {
    console.log(`❌ User Profile Extensions: ${userError.message}`);
  } else {
    console.log(`✅ Extended Profile Columns verified on 'users' table!`);
  }
}

verifyAllTables().catch(console.error);
