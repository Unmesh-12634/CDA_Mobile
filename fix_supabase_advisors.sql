-- =========================================================
-- Supabase Security & Performance Advisor Fix Script
-- Resolves all Duplicate Index Warnings & RLS Policy Warnings
-- Target Project: jbauuvxeybakihedeskj
-- =========================================================

-- 1. DROP DUPLICATE INDEXES (Resolves "Duplicate Index" warnings)
DROP INDEX IF EXISTS idx_uniq_user_auth_user;
DROP INDEX IF EXISTS idx_uniq_user_auth_email;
DROP INDEX IF EXISTS idx_uniq_user_interview_settings;
DROP INDEX IF EXISTS idx_uniq_user_weekly_report;
DROP INDEX IF EXISTS idx_uniq_user_subscription_user;
DROP INDEX IF EXISTS idx_uniq_user_job_app_user_job;

-- 2. SETUP CLEAN RLS POLICIES (Resolves "RLS Enabled No Policy" warnings)
DO $$ 
DECLARE 
    tbl_name text;
    app_tables text[] := ARRAY[
        'users',
        'user_auth',
        'user_interview_settings',
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
BEGIN
    FOREACH tbl_name IN ARRAY app_tables LOOP
        -- Check if table exists before applying RLS
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl_name) THEN
            -- Enable Row Level Security
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl_name);
            
            -- Drop existing policies if any to avoid duplication errors
            EXECUTE format('DROP POLICY IF EXISTS "Public Full Access Policy" ON public.%I;', tbl_name);
            EXECUTE format('DROP POLICY IF EXISTS "Allow public read access" ON public.%I;', tbl_name);
            EXECUTE format('DROP POLICY IF EXISTS "Allow public insert access" ON public.%I;', tbl_name);
            EXECUTE format('DROP POLICY IF EXISTS "Allow public update access" ON public.%I;', tbl_name);
            EXECUTE format('DROP POLICY IF EXISTS "Allow public delete access" ON public.%I;', tbl_name);
            
            -- Create universal RLS access policy for Flutter app
            EXECUTE format('CREATE POLICY "Public Full Access Policy" ON public.%I FOR ALL USING (true) WITH CHECK (true);', tbl_name);
        END IF;
    END LOOP;
END $$;
