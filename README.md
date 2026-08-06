# Updated Application Backend & Supabase Database Integration

This repository contains the updated database architecture, migration DDL scripts, and Supabase client integration for the application.

## 📁 Repository Structure

```
├── schema_v2.sql           # Complete PostgreSQL DDL migration script (12 tables)
├── supabaseClient.js       # Supabase JS SDK client instance
├── verify_schema.js        # Automated database verification & health check script
├── .env.example            # Template environment variables
├── package.json            # Node.js dependencies
└── README.md               # Project documentation
```

## 🗄️ Database Architecture (12 Core Tables)

1. **`users`**: Candidate & student profiles, contact details, learning streaks.
2. **`companies`**: Organization profiles, industries, logos, headquarters.
3. **`jobs`**: Job postings, salary ranges, work mode, required skills.
4. **`saved_jobs`**: Bookmarked jobs per user.
5. **`job_applications`**: Candidate application pipeline status (`Applied`, `Under Review`, `Interview Scheduled`, `Offered`, `Rejected`).
6. **`reels`**: Short learning video content, stream URLs, views, likes, tags.
7. **`saved_reels`**: Bookmarked video reels.
8. **`daily_questions` & `quiz_attempts`**: Scheduled daily quizzes, options, explanations, and user attempt tracking.
9. **`user_settings`**: App theme, push/email notification preferences.
10. **`ai_interview_reports`**: AI mock interview evaluation, scores, feedback, strengths, and Q&A transcripts.
11. **`user_progress`**: Unified progress tracking across reels, quizzes, and learning modules.

## 🚀 Quick Setup Instructions

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Configure Environment Variables**:
   Copy `.env.example` to `.env` and fill in your Supabase credentials:
   ```bash
   cp .env.example .env
   ```

3. **Verify Database Connection & Tables**:
   ```bash
   node verify_schema.js
   ```

## 📜 Database Migration

To run or re-apply the database DDL script in Supabase:
- Copy the contents of `schema_v2.sql`.
- Open the [Supabase SQL Editor](https://supabase.com/dashboard).
- Paste and click **Run**.
