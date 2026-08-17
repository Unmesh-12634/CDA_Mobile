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
-- 9. QUIZ RESULTS TABLE (AI-Powered Quiz Tracking)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quiz_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    score INT NOT NULL DEFAULT 0,           -- 0-100 percentage
    correct_count INT NOT NULL DEFAULT 0,
    total_questions INT NOT NULL DEFAULT 5,
    category VARCHAR(100) DEFAULT 'Mixed',  -- e.g. 'System Design', 'Flutter', 'Mixed'
    skill_focus VARCHAR(255),               -- derived from user weak areas
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_quiz_results_email ON public.quiz_results(user_email, completed_at DESC);

-- ─────────────────────────────────────────────────────────────────────────
-- 10. COMPANIES SEED DATA (CDA Partner Companies)
-- ─────────────────────────────────────────────────────────────────────────
INSERT INTO public.companies (id, name, logo_url, website, industry, headquarters, description, is_active)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Infosys', 'https://upload.wikimedia.org/wikipedia/commons/9/95/Infosys_logo.svg', 'https://www.infosys.com', 'IT Services & Consulting', 'Bengaluru, India', 'Global leader in digital services and consulting, enabling clients in more than 50 countries to navigate digital transformation.', true),
  ('a1000000-0000-0000-0000-000000000002', 'TCS', 'https://upload.wikimedia.org/wikipedia/commons/b/b1/Tata_Consultancy_Services_Logo.svg', 'https://www.tcs.com', 'IT Services & Consulting', 'Mumbai, India', 'Tata Consultancy Services is an IT services, consulting and business solutions organization.', true),
  ('a1000000-0000-0000-0000-000000000003', 'Wipro', 'https://upload.wikimedia.org/wikipedia/commons/a/a0/Wipro_Primary_Logo_Color_RGB.svg', 'https://www.wipro.com', 'IT Services & Consulting', 'Bengaluru, India', 'Wipro Limited is a global IT, consulting and business process services company.', true),
  ('a1000000-0000-0000-0000-000000000004', 'Cognizant', 'https://upload.wikimedia.org/wikipedia/commons/3/34/Cognizant_logo.svg', 'https://www.cognizant.com', 'IT Services & Digital Engineering', 'New Jersey, USA', 'Cognizant helps modern businesses evolve while building a more equitable and sustainable future.', true),
  ('a1000000-0000-0000-0000-000000000005', 'Capgemini', 'https://upload.wikimedia.org/wikipedia/commons/9/91/Capgemini_201x_logo.svg', 'https://www.capgemini.com', 'Technology & Management Consulting', 'Paris, France', 'A global leader in partnering with companies to transform and manage their business by harnessing the power of technology.', true),
  ('a1000000-0000-0000-0000-000000000006', 'Tech Mahindra', 'https://upload.wikimedia.org/wikipedia/commons/8/80/Tech_Mahindra_New_Logo.png', 'https://www.techmahindra.com', 'IT Services & Telecom', 'Pune, India', 'Tech Mahindra is a leading provider of digital transformation, consulting and business re-engineering services.', true),
  ('a1000000-0000-0000-0000-000000000007', 'HCL Technologies', 'https://upload.wikimedia.org/wikipedia/commons/4/44/HCL_Technologies_logo.svg', 'https://www.hcltech.com', 'IT & Digital Services', 'Noida, India', 'HCL Technologies is a next-generation global technology company that helps enterprises reimagine their businesses.', true),
  ('a1000000-0000-0000-0000-000000000008', 'Accenture', 'https://upload.wikimedia.org/wikipedia/commons/c/cd/Accenture.svg', 'https://www.accenture.com', 'Professional Services & Consulting', 'Dublin, Ireland', 'A leading global professional services company offering services and solutions in strategy, consulting, technology and operations.', true),
  ('a1000000-0000-0000-0000-000000000009', 'IBM India', 'https://upload.wikimedia.org/wikipedia/commons/5/51/IBM_logo.svg', 'https://www.ibm.com/in-en', 'Technology & Cloud Services', 'Bengaluru, India', 'IBM is a multinational technology corporation producing computer hardware, middleware, and software.', true),
  ('a1000000-0000-0000-0000-000000000010', 'Mphasis', 'https://upload.wikimedia.org/wikipedia/commons/d/de/Mphasis-Logo.svg', 'https://www.mphasis.com', 'IT Services & BPO', 'Bengaluru, India', 'Mphasis applies next-generation technology to help enterprises transform across the two key imperatives of customer centricity and operational effectiveness.', true)
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────
-- 11. CDA COURSES CATALOG (Cranes Varsity Website / Video Modules)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cda_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    link_url TEXT NOT NULL DEFAULT 'https://www.youtube.com/watch?v=Uf6PXnagtsg',
    tags TEXT[] NOT NULL DEFAULT '{}',
    thumbnail_url TEXT,
    estimated_duration VARCHAR(50) DEFAULT '12 Weeks',
    difficulty_level VARCHAR(50) DEFAULT 'Intermediate to Advanced',
    priority VARCHAR(20) DEFAULT 'HIGH',
    is_featured BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cda_courses_category ON public.cda_courses(category);
CREATE INDEX IF NOT EXISTS idx_cda_courses_active ON public.cda_courses(is_active, is_featured);

INSERT INTO public.cda_courses (id, title, category, description, link_url, tags, thumbnail_url, estimated_duration, difficulty_level, priority, is_featured, is_active)
VALUES
  (
    'c0000000-0000-0000-0000-000000000001',
    'Full-Stack Java Enterprise & Microservices Masterclass',
    'Java & Backend',
    'Comprehensive industry-grade program covering Core Java 17, Spring Boot 3, Microservices Architecture, Spring Cloud, Kafka, and PostgreSQL optimization.',
    'https://www.youtube.com/watch?v=Uf6PXnagtsg',
    ARRAY['#Java', '#SpringBoot', '#Microservices', '#Kafka', '#PostgreSQL', '#SystemDesign'],
    'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600&auto=format&fit=crop&q=80',
    '12 Weeks',
    'Intermediate to Advanced',
    'HIGH',
    true,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000002',
    'System Design & Distributed High-Throughput Architecture',
    'System Design',
    'Master large-scale system design: load balancing, horizontal sharding, caching strategies (Redis), event-driven messaging, and zero-downtime deployments.',
    'https://www.youtube.com/watch?v=Uf6PXnagtsg',
    ARRAY['#SystemDesign', '#DistributedSystems', '#Scalability', '#Redis', '#AWS', '#Microservices'],
    'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
    '8 Weeks',
    'Advanced',
    'HIGH',
    true,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000003',
    'Python AI, Deep Learning & Generative AI Engineering',
    'AI & Data Science',
    'End-to-end GenAI & Machine Learning: PyTorch, Transformers, LLM Fine-Tuning, LangChain, RAG architectures, and Vector Databases (Pinecone/ChromaDB).',
    'https://www.youtube.com/watch?v=Uf6PXnagtsg',
    ARRAY['#Python', '#MachineLearning', '#PyTorch', '#GenAI', '#LangChain', '#LLMs'],
    'https://images.unsplash.com/photo-1677442136019-21780efad99a?w=600&auto=format&fit=crop&q=80',
    '14 Weeks',
    'Intermediate to Advanced',
    'HIGH',
    true,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000004',
    'Embedded Systems, RTOS & Automotive IoT Architecture',
    'Embedded & IoT',
    'Cranes flagship program on Embedded C, ARM Cortex Microcontrollers, FreeRTOS, CAN Bus protocols, and real-time automotive firmware design.',
    'https://www.youtube.com/watch?v=Uf6PXnagtsg',
    ARRAY['#EmbeddedC', '#RTOS', '#ARMCortex', '#IoT', '#Automotive', '#Firmware'],
    'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&auto=format&fit=crop&q=80',
    '16 Weeks',
    'Beginner to Advanced',
    'HIGH',
    true,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000005',
    'Modern Cross-Platform Flutter & Clean Architecture',
    'Mobile Development',
    'Production Flutter: Riverpod state management, Clean Architecture, CI/CD pipelines, Native platform channels, and high-performance animations.',
    'https://www.youtube.com/watch?v=Uf6PXnagtsg',
    ARRAY['#Flutter', '#Dart', '#Riverpod', '#CleanArchitecture', '#MobileDev', '#iOSAndroid'],
    'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=600&auto=format&fit=crop&q=80',
    '8 Weeks',
    'Intermediate',
    'MEDIUM',
    true,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000006',
    'Cloud DevOps, Docker & Kubernetes Production Engineering',
    'DevOps & Cloud',
    'Containerization with Docker, Kubernetes orchestration, Helm, Terraform Infrastructure as Code (IaC), and resilient GitOps with ArgoCD.',
    'https://www.youtube.com/watch?v=Uf6PXnagtsg',
    ARRAY['#DevOps', '#Kubernetes', '#Docker', '#AWS', '#CI_CD', '#Terraform'],
    'https://images.unsplash.com/photo-1667372393119-3d4c48d07fc9?w=600&auto=format&fit=crop&q=80',
    '10 Weeks',
    'Intermediate to Advanced',
    'HIGH',
    true,
    true
  )
ON CONFLICT (id) DO NOTHING;

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
ALTER TABLE public.quiz_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cda_courses ENABLE ROW LEVEL SECURITY;

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

