# CDA AI Mock Interviewer System (Python)

> An intelligent, adaptive, real-time AI mock interviewer built for candidate preparation. Uses LLM-driven strategy, continuous evaluation, and dynamic question generation based on candidate performance, job roles, and optional resumes.

---

## 📌 Features

- 📄 **Optional Resume Analysis**: Parses PDF/DOCX resumes using `pypdf` / `python-docx` and extracts structured candidate profiles.
- 🎯 **Role & Strategy Customization**: Supports 10+ standard technical roles (or any custom job role), multiple difficulty levels, and interview styles (Technical, HR, Behavioral, Resume-based, Mixed).
- 🧠 **Adaptive Interview Engine**: Questions adapt dynamically turn-by-turn (follow-ups, deeper architectural probes, fundamental clarification) based on candidate answers.
- 📊 **Real-time Evaluation & Memory**: Scores technical accuracy, clarity, and depth without breaking interviewer persona. Deduplicates questions and manages context windows.
- 📝 **Comprehensive Performance Reports**: Produces overall score, category breakdown (Technical, Communication, Problem Solving, Role Readiness), strengths, study suggestions, and itemized Q&A reviews. Saved locally as structured `.json` and formatted `.txt`.
- 🔌 **Decoupled Architecture**: Designed around a domain service layer (`InterviewService`) so the core engine can be seamlessly attached to FastAPI, Spring Boot, WebSockets, or Voice interfaces (STT/TTS).

---

## 📁 Project Architecture & Folder Structure

```
AI-Interview/
├── main.py                     # Interactive CLI entry point
├── requirements.txt            # Project dependencies
├── .env.example                # Template environment file
├── .gitignore                  # Git exclusions (ignores secrets & reports)
├── README.md                   # System documentation
│
├── config/
│   └── settings.py             # Application settings & environment loader
│
├── agents/
│   ├── interview_planner.py    # Strategic interview plan generator
│   ├── answer_evaluator.py     # Turn-by-turn answer scoring & action selector
│   ├── interview_agent.py      # Adaptive next-question generator
│   └── report_agent.py         # Comprehensive report synthesizer
│
├── services/
│   ├── groq_service.py         # Centralized Groq API gateway (retries, JSON mode)
│   ├── resume_service.py       # PDF/DOCX resume text parser & profile builder
│   └── interview_service.py    # Decoupled domain engine facade
│
├── models/
│   ├── candidate.py            # CandidateProfile & WorkExperience models
│   ├── question.py             # Question, QuestionType, Difficulty models
│   ├── evaluation.py           # AnswerEvaluation model
│   └── interview.py            # InterviewConfig, InterviewPlan, Report models
│
├── prompts/
│   ├── resume_prompt.py        # Resume extraction prompt template
│   ├── planner_prompt.py       # Strategy planning prompt template
│   ├── interviewer_prompt.py   # Interviewer persona & transition prompt template
│   ├── evaluation_prompt.py    # Answer evaluation prompt template
│   └── report_prompt.py        # Final report generation prompt template
│
├── memory/
│   └── interview_memory.py     # Turn state, topic tracking, adaptive difficulty
│
├── utils/
│   ├── file_utils.py           # File validation, PDF/DOCX extractors, report writer
│   ├── json_utils.py           # Markdown JSON stripper & Pydantic validator
│   └── logger.py               # Secure logging setup
│
├── data/
│   ├── resumes/                # Store optional PDF/DOCX resumes
│   └── reports/                # Output directory for saved JSON and TXT reports
│
└── tests/                      # Pytest unit tests (Groq API mocked)
    ├── test_groq_config.py
    ├── test_interview_memory.py
    ├── test_question_duplication.py
    ├── test_answer_evaluator.py
    └── test_report_generator.py
```

---

## 🚀 Getting Started (Windows PowerShell Setup)

Follow these exact commands to set up and run the application locally:

### 1. Navigate to Project Directory
```powershell
cd "d:\Projects\Cranes app\AI-Interview"
```

### 2. Create and Activate Virtual Environment
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

### 3. Install Dependencies
```powershell
pip install -r requirements.txt
```

### 4. Configure Environment Variables
Copy the `.env.example` template to `.env`:
```powershell
Copy-Item .env.example .env
```
Open `.env` in your text editor and set your **Groq API Key**:
```env
GROQ_API_KEY=gsk_your_actual_groq_api_key_here
GROQ_MODEL=llama-3.3-70b-versatile
```

---

## 💻 Running the Terminal Application

To launch the interactive CLI interviewer:
```powershell
python main.py
```

### Example Terminal Interaction Flow
```text
========================================
       CDA AI MOCK INTERVIEWER
========================================

Candidate Name: Unmesh
Select Job Role:
 1. Java Developer
 2. Full Stack Developer
 3. Frontend Developer
 ...
Enter choice (1-10): 6 (AI/ML Engineer)

Select Interview Type: 1 (Technical)
Select Difficulty: 2 (Intermediate)
Select Interview Length: 1 (Short ~5 questions)
Resume File Path: data/resumes/my_resume.pdf

[Interviewer]: Welcome Unmesh. Let's begin by discussing your experience with Retrieval-Augmented Generation (RAG).
Question 1/5 [Technical | Intermediate]:
Can you walk me through the vector embedding indexing pipeline you implemented in your RAG project?

[Unmesh]: I used OpenAI embeddings with ChromaDB to index PDF documents...
```

---

## 🧪 Running Unit Tests

Run the test suite using `pytest`. All Groq API calls are safely mocked so no API credits are consumed:

```powershell
pytest
```

---

## 🔮 Future Architecture Extensions

### 🎙️ 1. Voice Integration (STT & TTS)
The engine is decoupled through `InterviewService.process_answer(session_id, answer_text) -> InterviewResponse`.
To add Voice:
- **Speech-to-Text (STT)** (e.g., Whisper / Groq Audio API): Converts candidate speech stream to string -> passes to `process_answer()`.
- **Text-to-Speech (TTS)** (e.g., ElevenLabs / Deepgram): Takes `response.current_question.text` and synthesizes audio stream back to user.

### 🌐 2. REST API / WebSocket Integration
The `InterviewService` methods easily wrap into API endpoints:
- `POST /api/interview/start` -> `InterviewService.start_session(config)`
- `POST /api/interview/respond` -> `InterviewService.process_answer(session_id, text)`
- `GET /api/interview/{id}/report` -> `InterviewService.end_session(session_id)`
