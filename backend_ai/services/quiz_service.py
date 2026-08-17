import json
import logging
from typing import Dict, List, Any, Optional
from .groq_service import GroqService
from .supabase_service import SupabaseRepository

logger = logging.getLogger("quiz_service")


class QuizService:
    """
    AI-powered quiz question generator.
    Analyzes the user's interview reports to find weak areas, then uses
    Groq Llama-3 to generate a fresh, personalized 5-question MCQ quiz.
    """

    def __init__(self):
        self.groq = GroqService()
        self.supabase = SupabaseRepository()

    def generate_quiz(self, user_email: str) -> Dict[str, Any]:
        """
        Returns 5 fresh MCQ questions tailored to the user's skill gaps.
        Falls back to a balanced mixed quiz if no data is available.
        """
        normalized_email = (user_email or "unii12634@gmail.com").strip().lower()

        # 1. Analyze weak areas from interview reports
        weak_areas, primary_skill = self._analyze_weak_areas(normalized_email)

        # 2. Generate questions via Groq
        questions = self._generate_questions(primary_skill, weak_areas)

        return {
            "skill_focus": primary_skill,
            "weak_areas": weak_areas,
            "questions": questions,
        }

    def _analyze_weak_areas(self, email: str):
        """Pulls last 3 interview reports, extracts lowest-scored categories."""
        primary_skill = "Full-Stack Development"
        weak_areas = ["System Design", "Data Structures", "Java Core"]

        try:
            result = self.supabase.client.table("ai_interview_reports") \
                .select("target_role, feedback_summary, overall_score") \
                .eq("candidate_email", email) \
                .order("created_at", desc=True) \
                .limit(3) \
                .execute()

            if result.data and len(result.data) > 0:
                roles = [r.get("target_role", "") for r in result.data if r.get("target_role")]
                if roles:
                    primary_skill = roles[0]

                # Extract feedback themes from summaries
                summaries = " ".join([r.get("feedback_summary", "") for r in result.data if r.get("feedback_summary")])
                weak_areas = self._extract_weakness_keywords(summaries, primary_skill)

        except Exception as e:
            logger.warning(f"Could not fetch interview reports for quiz: {e}")

        return weak_areas, primary_skill

    def _extract_weakness_keywords(self, text: str, role: str) -> List[str]:
        """Heuristic keyword extraction from feedback summaries."""
        categories = [
            "System Design", "Data Structures", "Algorithms", "Java Core",
            "Spring Boot", "Microservices", "Database Design", "SQL",
            "Flutter", "Dart", "API Design", "Behavioral", "Communication",
            "Problem Solving", "Design Patterns", "Cloud Architecture",
        ]
        found = [cat for cat in categories if cat.lower() in text.lower()]
        if not found:
            found = ["System Design", "Java Core", "Problem Solving"]
        return found[:4]

    def _generate_questions(self, skill: str, weak_areas: List[str]) -> List[Dict[str, Any]]:
        """Calls Groq to generate 5 MCQs, parses JSON response."""
        focus = ", ".join(weak_areas[:3]) if weak_areas else skill

        prompt = f"""You are a senior technical interviewer creating a rigorous MCQ quiz.
Generate exactly 5 multiple-choice questions for a {skill} candidate.
Focus on these weak areas: {focus}

Return ONLY valid JSON with this exact structure:
{{
  "questions": [
    {{
      "id": "q1",
      "category": "category name here",
      "question": "The full question text?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_index": 0,
      "explanation": "Why this answer is correct."
    }}
  ]
}}

Rules:
- Each question must be a genuinely challenging technical/practical scenario.
- Options must be plausible distractors — not obviously wrong.
- correct_index is 0-based (0 = first option).
- Cover these 5 distinct categories from: {focus}, plus related areas.
- No markdown, no extra text — just the JSON object."""

        try:
            raw = self.groq.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                max_tokens=2000,
            )
            content = raw.choices[0].message.content.strip()

            # Strip markdown code fences if present
            if content.startswith("```"):
                content = content.split("```")[1]
                if content.startswith("json"):
                    content = content[4:]
            content = content.strip()

            parsed = json.loads(content)
            questions = parsed.get("questions", [])

            if len(questions) == 5:
                return questions

        except Exception as e:
            logger.error(f"Groq quiz generation failed: {e}")

        # Fallback: hardcoded balanced quiz
        return self._fallback_questions(skill)

    def _fallback_questions(self, skill: str) -> List[Dict[str, Any]]:
        return [
            {
                "id": "q1",
                "category": "System Design",
                "question": f"In a high-traffic {skill} service, which rate limiting strategy allows sudden bursts while guaranteeing a fixed average rate?",
                "options": ["Token Bucket", "Leaky Bucket", "Fixed Window Counter", "Sliding Window Log"],
                "correct_index": 0,
                "explanation": "Token Bucket allows tokens to accumulate up to a max bucket size, enabling short bursts while maintaining a steady average rate."
            },
            {
                "id": "q2",
                "category": "Concurrency",
                "question": "Which Java primitive is guaranteed to prevent visibility issues across threads without synchronization overhead?",
                "options": ["volatile", "synchronized", "AtomicInteger", "ThreadLocal"],
                "correct_index": 0,
                "explanation": "volatile ensures memory visibility — reads always see the latest write from any thread — without mutual exclusion overhead."
            },
            {
                "id": "q3",
                "category": "Database Design",
                "question": "Which ACID property ensures that concurrent transactions execute without seeing each other's intermediate state?",
                "options": ["Atomicity", "Consistency", "Isolation", "Durability"],
                "correct_index": 2,
                "explanation": "Isolation prevents dirty reads and phantom reads by executing transactions as if they were serial."
            },
            {
                "id": "q4",
                "category": "API Design",
                "question": "Which HTTP status code should a REST API return when a resource is created successfully?",
                "options": ["200 OK", "201 Created", "204 No Content", "202 Accepted"],
                "correct_index": 1,
                "explanation": "201 Created is the semantically correct response when a new resource has been created, with a Location header pointing to it."
            },
            {
                "id": "q5",
                "category": "Microservices",
                "question": "What is the primary purpose of the Circuit Breaker pattern in microservices?",
                "options": [
                    "Reduce network latency",
                    "Prevent cascading failures by stopping requests to failing services",
                    "Load balance across service instances",
                    "Encrypt inter-service communication"
                ],
                "correct_index": 1,
                "explanation": "Circuit Breaker detects failure patterns and short-circuits requests to prevent cascading failures across dependent services."
            },
        ]
