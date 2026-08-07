-- =========================================================
-- Supabase Schema Extensions Script (v3)
-- Adds 5 new tables & column extensions for CDA Mobile Flutter App
-- Target Project: jbauuvxeybakihedeskj
-- =========================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Custom ENUM Types for Extensions
DO $$ BEGIN
    CREATE TYPE hire_recommendation_enum AS ENUM ('Strong Hire', 'Hire', 'Borderline', 'No Hire');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE job_stage_enum AS ENUM ('Saved', 'Applied', 'Screening', 'Interviewing', 'Offered', 'Rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE plan_tier_enum AS ENUM ('Free', 'Pro', 'FAANG Pass');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE subscription_status_enum AS ENUM ('Active', 'Cancelled', 'Expired');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;


-- =========================================================
-- 1️⃣ AI Mock Interview Sessions & Reports (ai_interview_session)
-- =========================================================
CREATE TABLE IF NOT EXISTS ai_interview_session (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    job_role VARCHAR(255) NOT NULL,
    seniority_level VARCHAR(50) DEFAULT 'Mid-Level',
    interview_type VARCHAR(50) DEFAULT 'Technical',
    difficulty VARCHAR(50) DEFAULT 'Medium',
    
    -- Numerical Scores out of 10.00 / 100.00
    overall_score NUMERIC(4,2) NOT NULL DEFAULT 0.00,
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


-- =========================================================
-- 2️⃣ Weekly Performance & Weekly Report (user_weekly_report)
-- =========================================================
CREATE TABLE IF NOT EXISTS user_weekly_report (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    
    total_study_minutes INT DEFAULT 0,
    mock_interviews_taken INT DEFAULT 0,
    avg_interview_score NUMERIC(4,2) DEFAULT 0.00,
    quizzes_completed INT DEFAULT 0,
    quiz_accuracy_pct NUMERIC(5,2) DEFAULT 0.00,
    streak_maintained_days INT DEFAULT 0,
    
    strongest_skill VARCHAR(100),
    weakest_skill VARCHAR(100),
    weekly_grade VARCHAR(5) DEFAULT 'B', -- 'A+', 'A', 'B', 'C', 'D'
    ai_recommendations JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_week UNIQUE (user_id, week_start_date)
);


-- =========================================================
-- 3️⃣ Job Application Pipeline Tracker (user_job_application)
-- =========================================================
CREATE TABLE IF NOT EXISTS user_job_application (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    job_opening_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    stage job_stage_enum DEFAULT 'Saved',
    applied_date DATE DEFAULT CURRENT_DATE,
    resume_used_url VARCHAR(500),
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- 4️⃣ Extended Profile & Career Target Fields (users table extensions)
-- =========================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_annual_package NUMERIC(12,2) DEFAULT 0.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_role VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS experience_years NUMERIC(3,1) DEFAULT 0.0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS github_url VARCHAR(500);
ALTER TABLE users ADD COLUMN IF NOT EXISTS linkedin_url VARCHAR(500);
ALTER TABLE users ADD COLUMN IF NOT EXISTS portfolio_url VARCHAR(500);
ALTER TABLE users ADD COLUMN IF NOT EXISTS resume_url VARCHAR(500);


-- =========================================================
-- 5️⃣ Subscription & Plan Tiers (user_subscription)
-- =========================================================
CREATE TABLE IF NOT EXISTS user_subscription (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan_tier plan_tier_enum DEFAULT 'Free',
    status subscription_status_enum DEFAULT 'Active',
    current_period_end TIMESTAMP WITH TIME ZONE,
    payment_reference VARCHAR(255),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- Idempotent Unique Indexes & Performance Indexes
-- =========================================================
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_user_job_app_user_job ON user_job_application(user_id, job_opening_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_user_subscription_user ON user_subscription(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_user_weekly_report ON user_weekly_report(user_id, week_start_date);

CREATE INDEX IF NOT EXISTS idx_ai_interview_session_user ON ai_interview_session(user_id);
CREATE INDEX IF NOT EXISTS idx_user_job_application_user ON user_job_application(user_id);
CREATE INDEX IF NOT EXISTS idx_user_weekly_report_user ON user_weekly_report(user_id);
