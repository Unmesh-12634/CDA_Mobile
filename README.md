# 🚀 Cranes Varsity Student Companion (CDA Mobile)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Java Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-6DB33F?logo=springboot)](https://spring.io/projects/spring-boot)
[![Supabase DB](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)](https://supabase.com)
[![Groq AI](https://img.shields.io/badge/Groq_AI-LLaMA_3.3_70B-F55036)](https://groq.com)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENSE)

> **The next-generation mobile career acceleration and micro-learning ecosystem designed for Cranes Varsity students.**

---

## 📖 Overview

The **Cranes Varsity Student App (CDA Mobile)** is an AI-powered mobile application designed to bridge the gap between classroom technical training and high-stakes placement interviews.

While traditional training programs rely on desktop portals, this application brings continuous learning, generative AI mock interviews, interactive reels, adaptive quizzes, and direct job placement tracking straight to students' smartphones.

---

## ✨ Key Features & Capabilities

### 🎙️ 1. Real-Time Generative AI Mock Interviewer
- **Powered by Groq LLaMA-3.3 70B Engine:** Sub-500ms token generation for fluid, conversational interviews.
- **Customizable Roles & Difficulty:** Practice for Java Developer, Flutter Engineer, Python / AI Engineer, Embedded Systems, and more.
- **Voice & Text Interaction:** Natural voice speech recognition and audio playback.
- **Instant Analysis Scorecard:** Comprehensive scoring across technical depth, communication, and problem-solving with actionable improvement tips.

### 📱 2. Byte-Sized Micro-Learning (Reels Tab)
- 60-second vertical high-definition video lessons covering key interview questions, architecture patterns, and quick tips.
- Fast, zero-buffering preload video caching.
- Social engagement with likes, comments, and bookmarking.

### ⚡ 3. Daily Adaptive Coding & Technical Drills
- AI-generated daily MCQs tailored to the user's specific domain and skill level.
- Midnight (12:00 AM) streak progression system to build a daily habit.
- Instant explanations for right and wrong answers.

### 💼 4. Direct Job & Placement Application Tracker
- Live job feed with detailed salary packages, eligibility, and skill tags.
- 1-tap job application attaching the student's cloud-stored resume.
- Transparent status tracking (*Applied → Shortlisted → Interviewing → Selected*).

### 📊 5. Industry-Ready Skill Radar & Analytics
- Automated domain scoring across Backend Engineering, Mobile Development, System Architecture, and Database Optimization.
- Visual strength gauge to help students and placement officers identify readiness.

---

## 🛠️ Architecture & Tech Stack

```
Frontend (Flutter Mobile) ──► Spring Boot Microservices (Java 17) ──► Groq AI / Supabase DB
```

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile Client** | **Flutter & Dart** | Cross-platform, responsive 60fps UI with Riverpod state management. |
| **Enterprise Backend** | **Spring Boot (Java 17)** | High-throughput business engine for scoring, analytics, and data aggregation. |
| **Cloud Database** | **Supabase PostgreSQL** | Secure relational database with Row Level Security (RLS) and real-time auth. |
| **AI Inference** | **Groq Cloud (LLaMA 3.3)** | Ultra-fast natural language processing and dynamic interview evaluation. |
| **Storage & CDN** | **Supabase Storage / Cloudinary** | Cloud storage for resumes, user avatars, and video streaming. |

---

## 🚀 Getting Started & Local Setup

### Prerequisites
- Flutter SDK (`>= 3.20.0`)
- Android Studio / VS Code with Flutter extension
- Java JDK 17+ (for backend services)
- Connected Android device with USB debugging enabled (or Android Emulator)

### 1. Frontend Setup
```bash
# Navigate to the frontend directory
cd frontend

# Fetch Flutter dependencies
flutter pub get

# Run on connected device in debug mode
flutter run

# Build release APK
flutter build apk --release
```

### 2. Java Backend Setup (Optional for Local API)
```bash
# Navigate to the backend directory
cd backend_java

# Build and run with Maven
mvn clean spring-boot:run
```

---

## 📦 Production Release Artifact
- **Compiled Release APK:** `frontend/build/app/outputs/flutter-apk/app-release.apk`
- **Output Size:** ~57.1 MB (Arm64 optimized)

---

## 📄 Business Pitch Presentation
For the complete executive business pitch deck prepared for the Cranes Varsity management team, see [PRESENTATION.md](PRESENTATION.md).

---

© 2026 Cranes Varsity. All Rights Reserved.
