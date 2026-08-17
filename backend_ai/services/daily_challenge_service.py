import os
import json
import logging
from datetime import date
from typing import Dict, List, Optional, Any
from .groq_service import GroqService
from .supabase_service import SupabaseRepository

logger = logging.getLogger("daily_challenge_service")

class DailyChallengeService:
    """Intelligent micro-challenge engine analyzing interview weak areas to generate daily targeted drills."""

    def __init__(self):
        self.groq = GroqService()
        self.supabase = SupabaseRepository()

    def get_or_generate_daily_challenge(self, user_email: str, force_refresh: bool = False) -> Dict[str, Any]:
        """Fetches today's challenge or dynamically synthesizes a fresh pair based on candidate weaknesses."""
        today_str = date.today().isoformat()
        normalized_email = (user_email or "unii12634@gmail.com").strip().lower()

        # 1. Check existing DB challenge for today unless forced refresh
        if not force_refresh:
            existing = self._fetch_db_challenge(normalized_email, today_str)
            if existing:
                return existing

        # 2. Extract Candidate Weaknesses & Skill Profile
        weaknesses, target_skill = self._analyze_candidate_weaknesses(normalized_email)

        # 3. Generate Fresh Targeted Question Pair via Groq Llama-3 in Real-Time
        challenge_data = self._generate_ai_questions(target_skill, weaknesses)

        # 4. Format record
        record = {
            "user_email": normalized_email,
            "challenge_date": today_str,
            "target_skill": target_skill,
            "weakness_focus": ", ".join(weaknesses[:2]) if weaknesses else target_skill,
            "question_1": challenge_data.get("question_1", f"In a high-traffic {target_skill} service, how do you diagnose and fix a connection pool starvation incident?"),
            "question_1_type": challenge_data.get("question_1_type", "PRODUCTION_RESILIENCE"),
            "question_1_model_answer": challenge_data.get("question_1_model_answer", "Configure circuit breakers, set connection acquisition timeouts, isolate slow downstream queries via bulkheads, and enable connection leak detection."),
            "question_2": challenge_data.get("question_2", f"What are the trade-offs between Optimistic Locking vs. Pessimistic Locking when managing concurrent transactions in {target_skill}?"),
            "question_2_type": challenge_data.get("question_2_type", "SYSTEM_TRADEOFF"),
            "question_2_model_answer": challenge_data.get("question_2_model_answer", "Optimistic locking minimizes lock contention but requires retry handling under high collisions; Pessimistic locking prevents conflicts upfront but risks lock queues and deadlock hazards."),
            "is_completed": False,
            "score": None,
        }

        saved = self._save_db_challenge(record)
        return saved if saved else record

    def evaluate_challenge_answer(
        self,
        question: str,
        model_answer: str,
        candidate_answer: str,
        skill: str,
    ) -> Dict[str, Any]:
        """Evaluates candidate answer against the model answer and returns rubric score & senior engineer feedback."""
        system_prompt = (
            "You are a Principal Software Engineering Interview Evaluator. Evaluate the candidate's response "
            "to a technical micro-challenge. Compare it against the ideal model answer.\n"
            "Return valid JSON ONLY in this exact format:\n"
            "{\n"
            '  "score": 85,\n'
            '  "feedback": "Clear explanation of the core mechanism and architectural trade-offs...",\n'
            '  "key_strengths": ["Clear explanation of concurrency control", "Addressed latency bottlenecks"],\n'
            '  "areas_to_improve": ["Mention specific retry backoff strategies", "Clarify memory visibility guarantees"],\n'
            '  "model_answer_summary": "Ideal senior engineer approach..."\n'
            "}"
        )

        user_content = (
            f"Technical Domain: {skill}\n"
            f"Question: {question}\n"
            f"Reference Model Answer: {model_answer}\n"
            f"Candidate Answer: {candidate_answer}\n"
        )

        try:
            raw_eval = self.groq.call_llama3(
                prompt=user_content,
                system_prompt=system_prompt,
                json_mode=True,
            )
            data = json.loads(raw_eval)
            return {
                "score": float(data.get("score", 80)),
                "feedback": data.get("feedback", "Good practical breakdown covering key architectural foundations."),
                "key_strengths": data.get("key_strengths", ["Solid technical understanding", "Addressed the primary problem"]),
                "areas_to_improve": data.get("areas_to_improve", ["Elaborate on edge-case failure modes and monitoring metrics"]),
                "model_answer_summary": data.get("model_answer_summary", model_answer),
            }
        except Exception as e:
            logger.warning(f"Groq evaluation fallback: {e}")
            return {
                "score": 80.0,
                "feedback": "Solid response covering the primary technical requirements and system patterns.",
                "key_strengths": ["Clear structural reasoning", "Addressed the core problem statement"],
                "areas_to_improve": ["Include numerical latency benchmarks and edge-case fallbacks"],
                "model_answer_summary": model_answer,
            }

    def _analyze_candidate_weaknesses(self, email: str) -> tuple[List[str], str]:
        """Extracts weak areas from past reports or falls back to user profile skills."""
        weaknesses: List[str] = []
        target_skill = "Java & Spring Boot"

        try:
            endpoint = f"{self.supabase.url}/rest/v1/ai_interview_reports?candidate_email=eq.{email}&order=created_at.desc&limit=5"
            res = self.supabase.headers
            import requests
            r = requests.get(endpoint, headers=res, timeout=6)
            if r.status_code == 200:
                reports = r.json()
                for report in reports:
                    imp = report.get("areas_for_improvement")
                    if isinstance(imp, list):
                        for item in imp:
                            if item and len(str(item).strip()) > 5:
                                weaknesses.append(str(item).strip())
                    elif isinstance(imp, str) and imp.strip():
                        weaknesses.append(imp.strip())

                    role = report.get("job_role")
                    if role and not target_skill:
                        target_skill = role
        except Exception as e:
            logger.warning(f"Failed to scan past reports for weaknesses: {e}")

        if not weaknesses:
            weaknesses = [
                "Handling Database Deadlocks and Query Latency spikes",
                "Designing Idempotent REST & Kafka Event Consumers",
                "State Management & Memory Leak Prevention",
            ]

        skills_rotation = [
            "Spring Boot Microservices",
            "Java Concurrency & Multithreading",
            "PostgreSQL Query Optimization & Indexing",
            "Flutter Architecture & Reactive State",
            "System Design & Distributed Caching",
            "Python, FastAPI & AI RAG Pipelines",
            "Docker, Kubernetes & Production CI/CD",
        ]
        target_skill = skills_rotation[date.today().weekday() % len(skills_rotation)]

        return weaknesses, target_skill

    def _generate_ai_questions(self, target_skill: str, weaknesses: List[str]) -> Dict[str, Any]:
        """Generates 2 focused scenario questions using Groq Llama-3."""
        system_prompt = (
            "You are a Principal Engineering Lead at a top tech company. Create 2 high-caliber, practical technical interview "
            "questions for a software engineering candidate. Do NOT ask trivial trivia; ask realistic architectural and debugging scenarios.\n"
            "Return valid JSON ONLY in this exact structure:\n"
            "{\n"
            '  "question_1": "Concrete real-world scenario testing core implementation mechanics...",\n'
            '  "question_1_type": "PRACTICAL_SCENARIO",\n'
            '  "question_1_model_answer": "Concise senior engineer answer explaining exact mechanism, classes/tools, and resolution...",\n'
            '  "question_2": "Architectural dilemma or trade-off question comparing two design choices...",\n'
            '  "question_2_type": "ARCHITECTURAL_TRADEOFF",\n'
            '  "question_2_model_answer": "Concise senior engineer answer comparing trade-offs, consistency vs latency, and the recommended approach..."\n'
            "}"
        )

        user_content = (
            f"Target Domain: {target_skill}\n"
            f"Candidate Weak Areas to Strengthen: {', '.join(weaknesses[:2])}\n"
            "Ensure the questions challenge the student to explain real mechanisms, trade-offs, and failure recoveries."
        )

        try:
            raw = self.groq.call_llama3(
                prompt=user_content,
                system_prompt=system_prompt,
                json_mode=True,
            )
            return json.loads(raw)
        except Exception as e:
            logger.warning(f"Groq question generation fallback: {e}")
            return {
                "question_1": f"In a high-load {target_skill} service, how do you prevent cascading database connection pool exhaustion when a downstream dependency slows down?",
                "question_1_type": "RESILIENCE_ENGINEERING",
                "question_1_model_answer": "Apply Circuit Breaker pattern (Resilience4j), enforce strict connection timeout thresholds, and implement non-blocking asynchronous request decoupling.",
                "question_2": f"When scaling {target_skill}, what are the trade-offs between Read Replicas with caching vs. Sharding by tenant ID?",
                "question_2_type": "DISTRIBUTED_SYSTEMS",
                "question_2_model_answer": "Read replicas are simpler but suffer from replication lag. Sharding scales write throughput horizontally but adds cross-shard transaction complexity.",
            }

    def _fetch_db_challenge(self, email: str, challenge_date: str) -> Optional[Dict[str, Any]]:
        """Queries Supabase for user's challenge on date."""
        try:
            import requests
            endpoint = f"{self.supabase.url}/rest/v1/ai_daily_challenges?user_email=eq.{email}&challenge_date=eq.{challenge_date}&limit=1"
            res = requests.get(endpoint, headers=self.supabase.headers, timeout=5)
            if res.status_code == 200:
                data = res.json()
                if data:
                    return data[0]
        except Exception as e:
            logger.warning(f"Failed to fetch DB challenge: {e}")
        return None

    def _save_db_challenge(self, record: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Saves generated challenge to Supabase."""
        try:
            import requests
            endpoint = f"{self.supabase.url}/rest/v1/ai_daily_challenges"
            res = requests.post(endpoint, headers=self.supabase.headers, json=record, timeout=5)
            if res.status_code in [200, 201]:
                data = res.json()
                if data:
                    return data[0]
        except Exception as e:
            logger.warning(f"Failed to save DB challenge: {e}")
        return None

daily_challenge_service = DailyChallengeService()
