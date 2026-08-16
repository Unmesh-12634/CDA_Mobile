# 🎓 CDA (Cranes Digital Academy) - Career Companion & AI Platform

[![Flutter](https://img.shields.io/badge/Frontend-Flutter%203.27-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Java Spring Boot](https://img.shields.io/badge/Backend-Java%2017%20Spring%20Boot-6DB33F?logo=springboot&logoColor=white)](https://spring.io)
[![Python AI](https://img.shields.io/badge/AI%20Engine-FastAPI%20%7C%20Groq%20Llama--3-3776AB?logo=python&logoColor=white)](https://fastapi.tiangolo.com)
[![Database](https://img.shields.io/badge/Database-Supabase%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Status](https://img.shields.io/badge/Completion-88%25%20Production%20Ready-brightgreen)]()

An enterprise-grade, full-stack AI-driven Career Companion application designed to empower students and professionals with **real-time AI mock interviews**, **adaptive learning roadmaps**, **dynamic career analytics**, **curated job matching**, and **12:00 AM calendar streak tracking**.

---

## 📊 Project Completion Status & Progress Matrix

| Module / Component | Technologies | Status | Completion % | Highlights & Capabilities |
| :--- | :--- | :---: | :---: | :--- |
| **🏠 Home & Activity Hub** | Flutter / Riverpod / Java | **Completed** | **95%** | Real 12:00 AM midnight rollover streak engine, dynamic 7-day tracker, live activity feeds, real-time unread notification bell. |
| **💼 Jobs & Application Tracker** | Flutter / Supabase / Java | **Completed** | **92%** | Real JD match scoring, profile auto-apply, live application lifecycle tracker (`Applied`, `Review`, `Interview`, `Offered`). |
| **🎥 Learn & Educational Reels** | Flutter / VideoPlayer / Java | **Completed** | **90%** | Zero-buffering preload pipeline, dynamic topic filtering, real-time likes, bookmarking, and timestamped comment threads. |
| **👤 Profile & Analytics** | Flutter / Supabase / Java | **Completed** | **92%** | Real dynamic profile strength calculator (100% data-driven), interactive GitHub/LinkedIn/Portfolio icons, AI domain readiness matrix. |
| **⚙️ Settings & Security** | Flutter / Java / TTS | **Completed** | **90%** | Live native TTS voice persona preview, real disk storage cache pruner, 2FA toggle, active device sessions, and GDPR JSON data export. |
| **☕ Enterprise Java Backend** | Java 17 / Spring Boot / JDBC | **Completed** | **90%** | REST APIs for activities, learning goals, weekly streaks, user settings, GDPR export, notifications, and profile analytics. |
| **🗄️ Database Architecture** | PostgreSQL / Supabase | **Completed** | **95%** | Single unified [`database/schema.sql`](database/schema.sql) with 14 master tables, performance indexes, and granular RLS security. |
| **🤖 AI Mock Interview & QnA** | Python / FastAPI / Groq / TTS | **In Progress** | **75%** | Dynamic JD tracks, Edge neural voice generation, live question answering. *Finishing touches & AI QnA evaluator tuning pending.* |

### 📈 **Overall Project Completion: 88%**

---

## 📁 Repository Structure

```
d:\Projects\Cranes app\
├── backend_java/          # ☕ Java 17 Spring Boot Enterprise Backend
│   ├── src/main/java/com/cda/backend/
│   │   ├── controller/    # REST Endpoints (User, Goals, Settings, Activities, Reels)
│   │   ├── dao/           # JDBC Data Access Objects & SQL Queries
│   │   ├── model/         # Java Domain Entities
│   │   └── service/       # Business Logic & GDPR Data Aggregator
│   └── pom.xml            # Maven Configuration
│
├── backend_ai/            # 🤖 Python AI Fast-API Microservice
│   ├── agents/            # Conversational Interviewer Agents
│   ├── prompts/           # System Prompts & Scoring Rubrics (Groq Llama-3)
│   ├── services/          # Edge Neural Voice Synthesizer & Speech Recognition
│   ├── api.py             # FastAPI REST & WebSocket Endpoints
│   └── requirements.txt   # Python Dependencies
│
├── database/              # 🗄️ Canonical Database Architecture
│   └── schema.sql         # ⭐ Single Unified Master PostgreSQL Schema
│
├── frontend/              # 📱 Flutter Cross-Platform Client Application
│   ├── lib/
│   │   ├── core/          # Network Clients (JavaApiService, SupabaseConfig, Theme)
│   │   ├── features/
│   │   │   ├── auth/          # Authentication & Secure Sessions
│   │   │   ├── home/          # Home Hub, Weekly Goal Provider, Live Activities
│   │   │   ├── interview/     # AI Interview Session, JDs, Analysis Screen
│   │   │   ├── jobs/          # Job Listings, Applications & Saved Jobs
│   │   │   ├── learn/         # Reels Feed, Video Preload & Comment Threads
│   │   │   ├── profile/       # Real-Time Profile Strength & Domain Scoring
│   │   │   ├── quiz/          # Practice Quizzes & Technical QnA
│   │   │   └── settings/      # Settings, Real TTS Tester & Cache Pruner
│   │   └── shared/        # Design System (GlassCard, GradientButton, Badges)
│   └── pubspec.yaml       # Flutter Dependencies
│
├── .agents/               # Antigravity Rules & Coding Guidelines
├── .gitignore             # Git Exclusions
└── README.md              # Project Documentation & Status Report
```

---

## 🌟 Key Features & Business Logic Implemented

### 1. 🕒 Strict 12:00 AM Midnight Learning Streak Engine
- **Calendar-Day Boundary**: Evaluates days at `00:00:00` midnight.
- **Consecutive Day Continuity**: Missing a day automatically marks today as pending; completing any core task restores streak momentum.
- **Task-Driven Unlocking**: Completing an AI Interview, finishing a Quiz, watching learning reels, or submitting a job application automatically checks off today's goal and persists across Java and PostgreSQL.

### 2. 👤 Real Profile Strength & Dynamic Domain Readiness
- **Mathematical Strength Score**: Calculated strictly on real profile completeness (Education, Passing Year, Portfolio URLs, Resume, Contact).
- **Interactive Social & Portfolio Icons**: GitHub, LinkedIn, and Portfolio links render brand logos and open external URLs via `url_launcher`.
- **AI Domain Matrix**: Computes readiness rankings across *Cloud & DevOps*, *AI & Machine Learning*, *Full Stack Java*, *Mobile Development*, and *System Architecture* based on active user engagement.

### 3. 🎙️ Live Voice Testing & Settings Center
- **Native TTS Voice Sandbox**: Real-time auditory preview for AI Voice Personas (*Samantha*, *David*, *Alex*, *Sophia*) using on-device neural speech synthesis.
- **Real Cache Pruning**: Reads physical temp files and image cache bytes, clearing disk storage and displaying freed space.
- **GDPR Account Archive**: One-tap structured JSON export of all user records, scores, and application history.

### 4. 🗄️ Single Canonical Master Database Schema
- Centralized in [`database/schema.sql`](database/schema.sql) with 14 normalized tables:
  `users`, `user_auth`, `companies`, `jobs`, `saved_jobs`, `job_applications`, `interview_blocks`, `ai_interview_reports`, `user_interview_settings`, `reels`, `saved_reels`, `reel_likes`, `reel_comments`, `user_learning_goals`, `user_settings`, and `notifications`.

---

## ⏳ Pending & Upcoming Milestones

- 🔄 **AI Interview Finishing Touches**: Fine-tuning latency and turn-transition phrasing in the Groq Llama-3 evaluator.
- 🎯 **AI QnA & Technical Deep-Dive Evaluator**: Advanced algorithmic feedback with numerical code complexity scoring.
- 📊 **Real-time Push Notifications**: FCM / APNs integration with automated streak reminder cron jobs.

---

## 🚀 Getting Started

### 1. Database Setup
1. Copy the contents of [`database/schema.sql`](database/schema.sql).
2. Run the script in the **Supabase SQL Editor** for project `jbauuvxeybakihedeskj`.

### 2. Run Java Enterprise Backend
```bash
cd backend_java
mvn clean spring-boot:run
```
*Backend runs on `http://localhost:8080` (or `http://10.0.2.2:8080` on Android Emulator / local LAN IP).*

### 3. Run Python AI Engine
```bash
cd backend_ai
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn api:app --host 0.0.0.0 --port 8000 --reload
```

### 4. Run Flutter Mobile App
```bash
cd frontend
flutter pub get
flutter run
```

---

## 🛡️ License & Credits
Developed for **CDA (Cranes Digital Academy)**. All rights reserved.
