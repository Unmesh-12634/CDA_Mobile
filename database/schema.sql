-- =========================================================================
-- CDA CAREER COMPANION - UNIFIED MASTER DATABASE SCHEMA
-- Target Database: Supabase PostgreSQL (Project: jbauuvxeybakihedeskj)
-- Architecture: Enterprise Java Spring Boot + Flutter Client Integration
-- =========================================================================

-- Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────
-- 1. ENUM TYPES
-- ─────────────────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────────────────
-- 2. USERS & AUTH TABLES
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
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
    year_of_passing VARCHAR(50),
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    weekly_days_completed BOOLEAN[] DEFAULT ARRAY[false, false, false, false, false, false, false],
    last_active_date VARCHAR(50),
    total_study_minutes INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_email_verified BOOLEAN DEFAULT false,
    
    -- Extended Career & Portfolio Targets
    target_annual_package NUMERIC(12,2) DEFAULT 0.00,
    target_role VARCHAR(255),
    experience_years NUMERIC(3,1) DEFAULT 0.0,
    github_url VARCHAR(500),
    linkedin_url VARCHAR(500),
    resume_url VARCHAR(500),
    profile_strength_score INT DEFAULT 0,
    
    -- CDA Pro Subscription & Expiration Tracking
    is_pro_member BOOLEAN DEFAULT false,
    pro_plan VARCHAR(50) DEFAULT 'Standard Access',
    pro_started_at TIMESTAMP WITH TIME ZONE,
    pro_expires_at TIMESTAMP WITH TIME ZONE,
    ai_trials_remaining INT DEFAULT 5,
    ai_trials_total INT DEFAULT 5,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_auth (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
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

-- ─────────────────────────────────────────────────────────────────────────
-- 3. COMPANIES & JOBS TABLES
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.companies (
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

CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    logo_url TEXT,
    location VARCHAR(255),
    salary VARCHAR(100),
    job_type VARCHAR(100) DEFAULT 'Full-time',
    category VARCHAR(100) DEFAULT 'Software Development',
    work_mode work_mode_enum DEFAULT 'Remote',
    experience_level VARCHAR(50),
    description TEXT,
    requirements TEXT[],
    tags TEXT[],
    match_score INT DEFAULT 85,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.saved_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    job_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_email, job_id)
);

CREATE TABLE IF NOT EXISTS public.job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    job_id VARCHAR(255) NOT NULL,
    resume_url TEXT,
    status VARCHAR(50) DEFAULT 'Applied',
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_email, job_id)
);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. AI MOCK INTERVIEW TABLES
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.interview_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) DEFAULT 'Cranes Varsity' NOT NULL,
    description TEXT NOT NULL,
    required_skills TEXT[] DEFAULT '{}' NOT NULL,
    experience_level VARCHAR(50) DEFAULT 'Mid-Level' NOT NULL,
    interview_type VARCHAR(50) DEFAULT 'Technical' NOT NULL,
    difficulty VARCHAR(50) DEFAULT 'Intermediate' NOT NULL,
    target_question_count INT DEFAULT 5 NOT NULL,
    badge_tag VARCHAR(50) DEFAULT 'HOT JD' NOT NULL,
    icon_name VARCHAR(50) DEFAULT 'code' NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.ai_interview_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(255),
    candidate_email VARCHAR(255) NOT NULL,
    job_role VARCHAR(255) NOT NULL,
    experience_level VARCHAR(50),
    interview_type VARCHAR(50),
    overall_score NUMERIC(5,2) DEFAULT 0.0,
    technical_score NUMERIC(5,2) DEFAULT 0.0,
    communication_score NUMERIC(5,2) DEFAULT 0.0,
    problem_solving_score NUMERIC(5,2) DEFAULT 0.0,
    hiring_readiness VARCHAR(100),
    executive_summary TEXT,
    strong_areas TEXT[],
    areas_for_improvement TEXT[],
    question_reviews JSONB,
    completed_turns INT DEFAULT 0,
    target_turns INT DEFAULT 5,
    is_terminated_early BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_interview_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) UNIQUE NOT NULL,
    voice_persona VARCHAR(100) DEFAULT 'Samantha (Natural AI)',
    auto_record BOOLEAN DEFAULT true,
    realtime_audio BOOLEAN DEFAULT true,
    difficulty VARCHAR(50) DEFAULT 'Intermediate',
    target_question_count INT DEFAULT 5,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- 5. REELS & SOCIAL LEARNING
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_name VARCHAR(255) NOT NULL,
    author_handle VARCHAR(255) NOT NULL,
    author_avatar_url TEXT,
    title VARCHAR(255),
    description TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    topic_category VARCHAR(100) DEFAULT 'General Tech',
    hashtags TEXT[],
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.saved_reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    reel_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_email, reel_id)
);

CREATE TABLE IF NOT EXISTS public.reel_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    reel_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_email, reel_id)
);

CREATE TABLE IF NOT EXISTS public.reel_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reel_id VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    user_avatar TEXT,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- 6. LEARNING GOALS, USER SETTINGS & NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_learning_goals (
    user_email VARCHAR(255) PRIMARY KEY,
    target_days INT DEFAULT 7,
    completed_days_count INT DEFAULT 0,
    total_hours_learned NUMERIC(5,1) DEFAULT 0.0,
    streak_count INT DEFAULT 0,
    last_active_date VARCHAR(50),
    next_goal_suggestion TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_settings (
    user_email VARCHAR(255) PRIMARY KEY,
    ai_voice_persona VARCHAR(100) DEFAULT 'Samantha (Natural AI)',
    realtime_audio BOOLEAN DEFAULT true,
    auto_record BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    haptic_feedback BOOLEAN DEFAULT true,
    theme_mode VARCHAR(50) DEFAULT 'system',
    two_factor_enabled BOOLEAN DEFAULT false,
    updated_at VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'system',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    user_email VARCHAR(255) NOT NULL,
    plan_name VARCHAR(100) NOT NULL,
    billing_cycle VARCHAR(50) NOT NULL, -- '1_hour', '1_day', '1_month', '3_months', '1_year'
    amount_paid NUMERIC(10,2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'INR',
    payment_method VARCHAR(50) DEFAULT 'UPI',
    payment_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'Active', -- 'Active', 'Expired', 'Cancelled'
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_email ON public.user_subscriptions(user_email);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);

-- ─────────────────────────────────────────────────────────────────────────
-- 7. PERFORMANCE INDEXES
-- ─────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_jobs_active ON public.jobs(is_active, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_job_apps_user ON public.job_applications(user_email, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_interview_reports_email ON public.ai_interview_reports(candidate_email, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_interview_blocks_active ON public.interview_blocks(is_active, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_reels_email ON public.saved_reels(user_email);
CREATE INDEX IF NOT EXISTS idx_reel_comments_reel ON public.reel_comments(reel_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_email, is_read, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_interview_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_interview_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_learning_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Permissive App Read/Write RLS Rules for Authenticated & Anon API Operations
DO $$
DECLARE
    tbl text;
BEGIN
    FOR tbl IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Allow All Ops" ON public.%I', tbl);
        EXECUTE format('CREATE POLICY "Allow All Ops" ON public.%I FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true)', tbl);
    END LOOP;
END $$;
