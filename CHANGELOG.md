# 📋 Changelog — Cranes Digital Academy (CDA) Mobile

All notable changes to the Cranes Digital Academy student ecosystem will be documented in this file.

---

## [v2.2.0] — 2026-08-20 (Enterprise Cloud & AI Release)

### 🌟 Major Highlights & New Features

- **🗄️ Supabase Storage Buckets for Avatars & Resumes**:
  - Implemented permissive Row Level Security (RLS) policies for `avatars` (10MB) and `resumes` (20MB) buckets with public `SELECT` and secure `INSERT`/`UPDATE`/`DELETE` capabilities.
  - User profile images upload directly to `avatars/avatar_{user_email}.{ext}` with cache-busting timestamping.
  - Student PDF resumes upload directly to `resumes/{user_email}/{fileName}.pdf` and automatically persist in the user profile state.

- **💬 Live Reels Engagement & Comment Engine**:
  - Populated 29+ genuine, high-quality technical comments across all 18 curriculum reels.
  - Linked 109+ verified likes with in-flight debouncing and database collision protection (`reel_likes`).
  - Real-time comment sheet with emoji shortcuts, instant deletion dialogs, and auto-synced `comments_count` and `likes_count`.

- **🤖 AI Interview Service Resiliency & Outage Grace Protocol**:
  - Added live health checks against the Render backend & Groq AI engine.
  - When backend services are restarting or offline, displays an intuitive **"AI Service Notice: Out of Service for now, please try again in 10 mins"** banner with a live ticking countdown timer (`10:00` ➔ `00:00`) and quick retry action.

- **💾 Local Cache & Phone-First Settings Management**:
  - Implemented `LocalCacheService` with SharedPreferences & FlutterSecureStorage.
  - User settings (Dark mode, push notifications, speech rate, sound effects, audio volume) persist on the client device without redundant database roundtrips.
  - Scoped `clearUserSessionData()` for secure memory wipes on sign-out while preserving device preferences.

- **🛡️ Level 4 Production Hardening**:
  - Integrated `WidgetsBindingObserver` auto-flush preserving in-progress mock interviews if the app is minimized or closed.
  - Input validation guard preventing accidental empty/noise submissions.
  - Type-safe parameters across all providers and repositories.

---

## [v2.1.0] — 2026-08-18 (AI Voice & Dynamic Feedback Update)
- Multi-voice TTS engine with dynamic gender pitch modulation (US & UK English).
- Live speech-to-text integration with real-time waveform audio visualizer.
- Dynamic scoring algorithm (Technical, Communication, Problem Solving).
- Weekly goal streaks and personalized drill generation.

---

## [v2.0.0] — 2026-08-15 (PostgreSQL & Supabase Architecture Migration)
- Direct PostgreSQL integration via Supabase Client replacing legacy mock stores.
- 22 Production database tables configured with full relational constraints.
- Riverpod 2.0 state management architecture across Auth, Profile, Quiz, Reels, and Interview modules.
