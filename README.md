# 🎓 CDA (Cranes Digital Academy) - Career Companion & AI Platform

[![Flutter](https://img.shields.io/badge/Frontend-Flutter%203.27-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Java Spring Boot](https://img.shields.io/badge/Backend-Java%2017%20Spring%20Boot-6DB33F?logo=springboot&logoColor=white)](https://spring.io)
[![Python AI](https://img.shields.io/badge/AI%20Engine-FastAPI%20%7C%20Groq%20Llama--3-3776AB?logo=python&logoColor=white)](https://fastapi.tiangolo.com)
[![Database](https://img.shields.io/badge/Database-Supabase%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Status](https://img.shields.io/badge/Completion-94%25%20Production%20Ready-brightgreen)]()

An enterprise-grade, full-stack AI-driven Career Companion application designed to empower students and professionals with **real-time AI mock interviews**, **adaptive learning roadmaps**, **dynamic career analytics**, **curated job matching**, **12:00 AM calendar streak tracking**, **CDA Pro duration & audit engine**, and **real-time mobile push notifications**.

---

## 📊 Project Completion Status & Progress Matrix

| Module / Component | Technologies | Status | Completion % | Highlights & Capabilities |
| :--- | :--- | :---: | :---: | :--- |
| **🏠 Home & Activity Hub** | Flutter / Riverpod / Java | **Completed** | **98%** | 12:00 AM midnight rollover streak engine, dynamic 7-day tracker, live activity feeds, real-time unread notification bell & status bar alerts. |
| **👑 CDA Pro & Subscription Suite** | Flutter / Java / PostgreSQL | **Completed** | **96%** | Multi-duration engine (`1_hour`, `1_day`, `1_month`, `3_months`, `1_year`), exact timestamp expiry countdowns, auto-reversion, and `public.user_subscriptions` audit. |
| **🔔 Mobile & In-App Notification Center**| Android Native / Flutter / Java | **Completed** | **95%** | Instant heads-up push notifications with sound/vibration (WhatsApp/Instagram-style) + persistent In-App Notification Center (`/notifications`). |
| **💼 Jobs & Application Tracker** | Flutter / Supabase / Java | **Completed** | **95%** | Real JD skills-match scoring, profile auto-apply, live application lifecycle tracker (`Applied`, `Review`, `Interview`, `Offered`). |
| **👤 Profile & Strength Engine** | Flutter / Supabase / Java | **Completed** | **95%** | VIP Metallic Golden Avatar frame & crown badge for Pro members, data-driven profile strength percentage, and interactive action checklist modal. |
| **🎥 Learn & Educational Reels** | Flutter / VideoPlayer / Java | **Completed** | **92%** | Zero-buffering preload pipeline, dynamic topic filtering, real-time likes, bookmarking, and timestamped comment threads. |
| **⚙️ Settings & Security** | Flutter / Java / TTS | **Completed** | **92%** | Native TTS voice persona preview, physical disk storage cache pruner, 2FA toggle, active device sessions, and GDPR JSON data export. |
| **☕ Enterprise Java Backend** | Java 17 / Spring Boot / JDBC | **Completed** | **94%** | REST APIs for subscriptions, activities, learning goals, weekly streaks, user settings, GDPR export, notifications, and profile analytics. |
| **🗄️ Database Architecture** | PostgreSQL / Supabase | **Completed** | **98%** | Master [`database/schema.sql`](database/schema.sql) with 15 master tables, audit timeline logs, performance indexes, and granular RLS security. |
| **🤖 AI Mock Interview & QnA** | Python / FastAPI / Groq / TTS | **In Progress** | **80%** | Dynamic JD tracks, Edge neural voice generation, live question answering. *Finishing touches & AI QnA evaluator tuning.* |

### 📈 **Overall Project Completion: 94%**

---

## 📁 Repository Structure

```
d:\Projects\Cranes app\
├── backend_java/          # ☕ Java 17 Spring Boot Enterprise Backend
│   ├── src/main/java/com/cda/backend/
│   │   ├── controller/    # REST Endpoints (Subscription, User, Goals, Settings, Activities, Reels)
│   │   ├── dao/           # JDBC Data Access Objects & Audit Queries (SubscriptionDAO, etc.)
│   │   ├── model/         # Java Domain Entities (SubscriptionInfo, UserProfile, Reel, etc.)
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
│   └── schema.sql         # ⭐ Single Unified Master PostgreSQL Schema (15 Tables)
│
├── frontend/              # 📱 Flutter Cross-Platform Client Application
│   ├── lib/
│   │   ├── core/          # Network Clients, NotificationService, LocalCacheService, SupabaseConfig
│   │   ├── features/
│   │   │   ├── auth/          # Multi-Layer Session Persistence & Auto-Login
│   │   │   ├── home/          # Home Hub, Weekly Goal Provider, Live Activities & Auto-Alerts
│   │   │   ├── interview/     # AI Interview Session, JDs, Analysis Screen
│   │   │   ├── jobs/          # Job Listings, Applications & Saved Jobs
│   │   │   ├── learn/         # Reels Feed, Video Preload & Comment Threads
│   │   │   ├── notifications/ # In-App Notification Center & Badge Counter
│   │   │   ├── profile/       # VIP Golden Avatar Frame, Strength Engine & Action Checklist
│   │   │   ├── subscription/  # CDA Pro Paywall Sheet, Duration Models & Validity Details
│   │   │   ├── quiz/          # Practice Quizzes & Technical QnA
│   │   │   └── settings/      # Settings, Real TTS Tester & Cache Pruner
│   │   └── shared/        # Design System (GlassCard, GradientButton, Badges)
│   ├── android/           # Android Native Config with Core Library Desugaring
│   └── pubspec.yaml       # Flutter Dependencies
│
├── .agents/               # Antigravity Rules & Coding Guidelines
├── .gitignore             # Git Exclusions
└── README.md              # Project Documentation & Status Report
```

---

## 🌟 Key Features & Business Logic Implemented

### 1. 👑 CDA Pro Duration Engine, Expiration & Multi-Table Audit
- **Flexible Pass Selection**: Supports `1_hour` (Quick Test Pass), `1_day` (Sprint Pass), `1_month` (Pro Plan), `3_months` (Quarter), and `1_year` (Annual Pass).
- **Exact Timestamp Expiry**: Computes precise start (`pro_started_at`) and end (`pro_expires_at`) timestamps down to the second.
- **Dedicated Audit Trail (`public.user_subscriptions`)**: Every purchase logs the plan name, billing cycle, amount paid (₹9, ₹49, ₹499, ₹1,199, ₹2,999), currency, payment method, and active dates.
- **Auto-Reversion**: Reverts automatically to Standard Free Tier upon expiration with zero app crash or data inconsistency.

### 2. 🔔 Real Mobile Push Notifications & In-App Notification Center
- **System Heads-Up Notifications**: Dispatched directly to the Android notification shade with sound and vibration (`flutter_local_notifications` + Core Desugaring).
- **App Launch & Login Triggers**: Automatically informs the student of remaining validity (`👑 CDA Pro Active • X days left`) or encourages free-tier exploration.
- **In-App Notification Center**: Synchronized in `public.notifications` with dynamic unread badge counters on the home screen bell icon.

### 3. 👤 VIP Metallic Golden Avatar Frame & Profile Strength Checklist
- **VIP Golden Frame**: Renders a luxury metallic sweep gradient border with amber backlighting and a `👑` crown pill badge for active Pro members.
- **Actionable Profile Strength Engine**: Real data-driven completion percentage with an interactive bottom sheet modal enabling one-tap completion of missing fields (Resume, Academics, Skills, Socials).

### 4. 🕒 Strict 12:00 AM Midnight Learning Streak Engine
- **Calendar-Day Boundary**: Evaluates days at `00:00:00` midnight.
- **Task-Driven Unlocking**: Completing an AI Interview, finishing a Quiz, watching learning reels, or submitting a job application automatically marks today's goal and persists across Java and PostgreSQL.

### 5. 🗄️ Master Database Schema
- Centralized in [`database/schema.sql`](database/schema.sql) with 15 normalized tables:
  `users`, `user_auth`, `user_subscriptions`, `companies`, `jobs`, `saved_jobs`, `job_applications`, `interview_blocks`, `ai_interview_reports`, `user_interview_settings`, `reels`, `saved_reels`, `reel_likes`, `reel_comments`, `user_learning_goals`, `user_settings`, and `notifications`.

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

## 👥 CDA Engineering Team & Contributors

Developed with ❤️ for **CDA (Cranes Digital Academy)**.

| Team Member | Role & Specialization | Key Responsibilities & Contributions |
| :--- | :--- | :--- |
| **👑 Unmesh** | **Project Lead & Full-Stack Architect** | • Overall System Architecture & Engineering Leadership<br>• Flutter Mobile Frontend & Core State Management<br>• Java 17 Spring Boot Enterprise Backend & REST APIs<br>• Python AI Fast-API & Edge Neural Voice System<br>• UI Motion, Physics Animations & Cross-Platform Orchestration |
| **🎨 Kalal Mansi** | **Frontend & UI/UX Specialist** | • Flutter Frontend Feature Development<br>• UI/UX Design System & Mobile Screen Layouts<br>• Interactive Micro-animations, Transitions & Visual Polish |
| **⚡ Shristi Bapna** | **Backend & Integration Specialist** | • Backend Integration & API Connectivity<br>• Client-Server Service Pipelines & Data Marshalling<br>• Business Logic & Integration Testing |
| **🗄️ Archi Lodha** | **Database & Data Management Specialist** | • Supabase PostgreSQL Schema Architecture & Migration<br>• Database Modeling, Relationships & Performance Indexing<br>• Row Level Security (RLS) Policy Design & Optimization |

---

## 🛡️ License & Copyright
© 2026 **CDA (Cranes Digital Academy)**. All rights reserved.
