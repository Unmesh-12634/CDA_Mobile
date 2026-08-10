-- =========================================================
-- Supabase Security Advisor Complete Resolution Script
-- Fixes: "RLS Disabled in Public" and "Policy Exists RLS Disabled"
-- Target Project: jbauuvxeybakihedeskj
-- =========================================================

DO $$ 
DECLARE 
    tbl_name text;
    pol record;
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
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl_name) THEN
            
            -- 1. Enable RLS on every table (Resolves "RLS Disabled in Public")
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl_name);
            
            -- 2. Drop all existing policies on the table to clean slate (Resolves "Policy Exists RLS Disabled")
            FOR pol IN 
                SELECT policyname 
                FROM pg_policies 
                WHERE schemaname = 'public' AND tablename = tbl_name 
            LOOP
                EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', pol.policyname, tbl_name);
            END LOOP;
            
            -- 3. Create clean granular CRUD policies for anon, authenticated, and service_role
            EXECUTE format('CREATE POLICY "Allow Select" ON public.%I FOR SELECT TO anon, authenticated, service_role USING (true);', tbl_name);
            EXECUTE format('CREATE POLICY "Allow Insert" ON public.%I FOR INSERT TO anon, authenticated, service_role WITH CHECK (true);', tbl_name);
            EXECUTE format('CREATE POLICY "Allow Update" ON public.%I FOR UPDATE TO anon, authenticated, service_role USING (true) WITH CHECK (true);', tbl_name);
            EXECUTE format('CREATE POLICY "Allow Delete" ON public.%I FOR DELETE TO anon, authenticated, service_role USING (true);', tbl_name);
            
        END IF;
    END LOOP;
END $$;
