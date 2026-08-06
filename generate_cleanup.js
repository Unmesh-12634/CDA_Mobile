const fs = require('fs');
const path = require('path');

const defs = JSON.parse(fs.readFileSync(path.join(__dirname, 'schema_dump.json'), 'utf8'));
const newTables = new Set([
  'users',
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
]);

const oldTables = Object.keys(defs).filter(t => !newTables.has(t));

let sql = `-- =========================================================
-- Cleanup Legacy Database Tables Script
-- Drops all ${oldTables.length} old tables, retaining ONLY the 12 updated tables created today
-- =========================================================

DROP TABLE IF EXISTS
${oldTables.map(t => '  ' + t).join(',\n')}
CASCADE;

-- Verification Query: List remaining active tables in public schema
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
`;

fs.writeFileSync(path.join(__dirname, 'cleanup_old_tables.sql'), sql);
console.log(`Successfully generated cleanup_old_tables.sql with ${oldTables.length} old tables to drop.`);
