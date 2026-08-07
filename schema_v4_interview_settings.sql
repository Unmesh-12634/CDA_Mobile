-- =========================================================
-- Supabase Schema Extension (user_interview_settings)
-- Candidate AI Voice & Interview Preference Settings Table
-- Target Project: jbauuvxeybakihedeskj
-- =========================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- User Interview Settings Table
CREATE TABLE IF NOT EXISTS user_interview_settings (
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    interviewer_voice VARCHAR(50) DEFAULT 'guy' NOT NULL, -- 'guy', 'aria', 'ryan', 'neerja', etc.
    speech_rate_multiplier NUMERIC(3,2) DEFAULT 1.00 NOT NULL, -- 0.8x, 1.0x, 1.2x speed
    preferred_mode VARCHAR(50) DEFAULT 'Technical' NOT NULL, -- Technical, HR, System Design, DSA
    preferred_difficulty VARCHAR(50) DEFAULT 'Medium' NOT NULL, -- Easy, Medium, Hard, FAANG Expert
    auto_submit_mic BOOLEAN DEFAULT true NOT NULL,
    show_live_transcript BOOLEAN DEFAULT true NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Idempotent Unique Index & Performance Index
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_user_interview_settings ON user_interview_settings(user_id);
