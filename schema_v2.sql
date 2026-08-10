-- =========================================================
-- Complete App Database Schema (Supabase PostgreSQL)
-- Target Project: jbauuvxeybakihedeskj
-- Includes RLS Policies & Clean Performance Indexes
-- =========================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Custom ENUM Types
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('User', 'Admin', 'Recruiter');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE work_mode_enum AS ENUM ('Remote', 'Onsite', 'Hybrid');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE application_status_enum AS ENUM ('Applied', 'Under Review', 'Interview Scheduled', 'Offered', 'Rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE hire_recommendation_enum AS ENUM ('Strong Hire', 'Hire', 'Borderline', 'No Hire');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE job_stage_enum AS ENUM ('Saved', 'Applied', 'Screening', 'Interviewing', 'Offered', 'Rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE plan_tier_enum AS ENUM ('Free', 'Pro', 'FAANG Pass');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE subscription_status_enum AS ENUM ('Active', 'Cancelled', 'Expired');
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- 2. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(150),
    avatar_url TEXT,
    role user_role_enum DEFAULT 'User',
    phone_number VARCHAR(20),
    degree VARCHAR(100),
    branch VARCHAR(100),
    college VARCHAR(200),
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_email_verified BOOLEAN DEFAULT false,
    
    -- Extended Profile & Career Target Fields
    target_annual_package NUMERIC(12,2) DEFAULT 0.00,
    target_role VARCHAR(255),
    experience_years NUMERIC(3,1) DEFAULT 0.0,
    github_url VARCHAR(500),
    linkedin_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    resume_url VARCHAR(500),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. User Auth Table
CREATE TABLE IF NOT EXISTS user_auth (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    auth_provider VARCHAR(50) DEFAULT 'email',
    provider_id VARCHAR(255),
    is_mfa_enabled BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip VARCHAR(45),
    password_reset_token VARCHAR(255),
    password_reset_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Companies Table
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    logo_url TEXT,
    website VARCHAR(255),
    industry VARCHAR(100),
    headquarters VARCHAR(255),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Jobs Table
CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    company_name VARCHAR(255) NOT NULL,
    company_logo TEXT,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    work_mode work_mode_enum DEFAULT 'Remote',
    job_type VARCHAR(50) DEFAULT 'Full-Time',
    job_category VARCHAR(100),
    salary_display VARCHAR(100),
    salary_min NUMERIC(12,2),
    salary_max NUMERIC(12,2),
    required_skills TEXT[],
    apply_url TEXT,
    application_deadline TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Saved Jobs Table
CREATE TABLE IF NOT EXISTS saved_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Job Applications Table
CREATE TABLE IF NOT EXISTS job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    status application_status_enum DEFAULT 'Applied',
    resume_url TEXT,
    cover_letter TEXT,
    notes TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. User Job Application (Pipeline Tracker)
CREATE TABLE IF NOT EXISTS user_job_application (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_opening_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    stage job_stage_enum DEFAULT 'Saved',
    applied_date DATE DEFAULT CURRENT_DATE,
    resume_used_url VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Reels / Short Videos Table
CREATE TABLE IF NOT EXISTS reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    duration_seconds INT DEFAULT 0,
    category VARCHAR(100),
    tags TEXT[],
    author_name VARCHAR(150),
    author_avatar TEXT,
    views_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 10. Saved Reels Table
CREATE TABLE IF NOT EXISTS saved_reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 11. Daily Questions & Quizzes
CREATE TABLE IF NOT EXISTS daily_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_option CHAR(1) NOT NULL,
    explanation TEXT,
    category VARCHAR(100),
    difficulty VARCHAR(20) DEFAULT 'Medium',
    scheduled_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES daily_questions(id) ON DELETE CASCADE,
    selected_option CHAR(1) NOT NULL,
    is_correct BOOLEAN NOT NULL,
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 12. User Settings Table
CREATE TABLE IF NOT EXISTS user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'system',
    push_notifications BOOLEAN DEFAULT true,
    email_alerts BOOLEAN DEFAULT true,
    job_alerts_enabled BOOLEAN DEFAULT true,
    daily_reminder_time TIME DEFAULT '09:00:00',
    preferred_language VARCHAR(10) DEFAULT 'en',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 13. User Interview Settings Table
CREATE TABLE IF NOT EXISTS user_interview_settings (
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    interviewer_voice VARCHAR(50) DEFAULT 'guy' NOT NULL,
    speech_rate_multiplier NUMERIC(3,2) DEFAULT 1.00 NOT NULL,
    preferred_mode VARCHAR(50) DEFAULT 'Technical' NOT NULL,
    preferred_difficulty VARCHAR(50) DEFAULT 'Medium' NOT NULL,
    auto_submit_mic BOOLEAN DEFAULT true NOT NULL,
    show_live_transcript BOOLEAN DEFAULT true NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 14. AI Interview Reports & Voice Sessions
CREATE TABLE IF NOT EXISTS ai_interview_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_role VARCHAR(255) NOT NULL,
    overall_score NUMERIC(5,2) NOT NULL,
    feedback_summary TEXT,
    strengths TEXT[],
    improvements TEXT[],
    detailed_qa_json JSONB,
    duration_seconds INT DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ai_interview_session (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_role VARCHAR(255) NOT NULL,
    seniority_level VARCHAR(50) DEFAULT 'Mid-Level',
    interview_type VARCHAR(50) DEFAULT 'Technical',
    difficulty VARCHAR(50) DEFAULT 'Medium',
    overall_score NUMERIC(4,2) DEFAULT 0.00,
    technical_score NUMERIC(4,2) DEFAULT 0.00,
    communication_score NUMERIC(4,2) DEFAULT 0.00,
    problem_solving_score NUMERIC(4,2) DEFAULT 0.00,
    resume_knowledge_score NUMERIC(4,2) DEFAULT 0.00,
    role_readiness_score NUMERIC(4,2) DEFAULT 0.00,
    hire_recommendation hire_recommendation_enum DEFAULT 'Borderline',
    recruiter_notes JSONB,
    trajectory_analysis TEXT,
    evidence_backed_conclusions JSONB,
    transcript_history JSONB,
    resume_pdf_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 15. User Weekly Report
CREATE TABLE IF NOT EXISTS user_weekly_report (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    total_study_minutes INT DEFAULT 0,
    mock_interviews_taken INT DEFAULT 0,
    avg_interview_score NUMERIC(4,2) DEFAULT 0.00,
    quizzes_completed INT DEFAULT 0,
    quiz_accuracy_pct NUMERIC(5,2) DEFAULT 0.00,
    streak_maintained_days INT DEFAULT 0,
    strongest_skill VARCHAR(100),
    weakest_skill VARCHAR(100),
    weekly_grade VARCHAR(5) DEFAULT 'B',
    ai_recommendations JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_week UNIQUE (user_id, week_start_date)
);

-- 16. User Subscription
CREATE TABLE IF NOT EXISTS user_subscription (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_tier plan_tier_enum DEFAULT 'Free',
    status subscription_status_enum DEFAULT 'Active',
    current_period_end TIMESTAMP WITH TIME ZONE,
    payment_reference VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 17. User Progress
CREATE TABLE IF NOT EXISTS user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL,
    item_id VARCHAR(255) NOT NULL,
    progress_pct INT DEFAULT 0,
    time_spent_seconds INT DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 18. Clean Performance Indexes (No Duplicate Unique Constraint Indexes)
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_saved_jobs_user_job ON saved_jobs(user_id, job_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_job_applications_user_job ON job_applications(user_id, job_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_user_job_app_user_job ON user_job_application(user_id, job_opening_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_saved_reels_user_reel ON saved_reels(user_id, reel_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_user_progress_item ON user_progress(user_id, item_type, item_id);

CREATE INDEX IF NOT EXISTS idx_user_auth_provider ON user_auth(auth_provider, provider_id);
CREATE INDEX IF NOT EXISTS idx_jobs_active ON jobs(is_active);
CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_user ON job_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_reels_active ON reels(is_active);
CREATE INDEX IF NOT EXISTS idx_saved_jobs_user ON saved_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_reels_user ON saved_reels(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user ON quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_interview_reports_user ON ai_interview_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_interview_session_user ON ai_interview_session(user_id);
CREATE INDEX IF NOT EXISTS idx_user_weekly_report_user ON user_weekly_report(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_user ON user_progress(user_id);

-- 19. Enable RLS and Granular Access Policies for App
DO $$ 
DECLARE 
    tbl_name text;
    pol record;
    app_tables text[] := ARRAY[
        'users', 'user_auth', 'user_interview_settings', 'companies', 'jobs', 
        'saved_jobs', 'job_applications', 'user_job_application', 'reels', 
        'saved_reels', 'daily_questions', 'quiz_attempts', 'user_settings', 
        'ai_interview_reports', 'ai_interview_session', 'user_weekly_report', 
        'user_subscription', 'user_progress'
    ];
BEGIN
    FOREACH tbl_name IN ARRAY app_tables LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl_name) THEN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl_name);
            
            FOR pol IN 
                SELECT policyname 
                FROM pg_policies 
                WHERE schemaname = 'public' AND tablename = tbl_name 
            LOOP
                EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', pol.policyname, tbl_name);
            END LOOP;
            
            EXECUTE format('CREATE POLICY "Allow Select" ON public.%I FOR SELECT TO anon, authenticated, service_role USING (true);', tbl_name);
            EXECUTE format('CREATE POLICY "Allow Insert" ON public.%I FOR INSERT TO anon, authenticated, service_role WITH CHECK (true);', tbl_name);
            EXECUTE format('CREATE POLICY "Allow Update" ON public.%I FOR UPDATE TO anon, authenticated, service_role USING (true) WITH CHECK (true);', tbl_name);
            EXECUTE format('CREATE POLICY "Allow Delete" ON public.%I FOR DELETE TO anon, authenticated, service_role USING (true);', tbl_name);
        END IF;
    END LOOP;
END $$;
