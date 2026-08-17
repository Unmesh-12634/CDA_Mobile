import json
import logging
import random
from typing import Dict, List, Any, Optional
from .groq_service import GroqService
from .supabase_service import SupabaseRepository

logger = logging.getLogger("quiz_service")


class QuizService:
    """
    AI-powered real-time skill drill & MCQ quiz question generator.
    Analyzes the user's profile, target role, candidate skills, and past interview reports
    to generate a completely fresh, personalized 5-question MCQ set via Groq Llama-3.
    """

    def __init__(self):
        self.groq = GroqService()
        self.supabase = SupabaseRepository()

    def generate_quiz(self, user_email: str) -> Dict[str, Any]:
        """
        Returns 5 fresh MCQ questions tailored to the user's profile, skills, and interview weak spots.
        """
        normalized_email = (user_email or "unii12634@gmail.com").strip().lower()

        # 1. Analyze user profile, skills, and past interview weak areas
        profile_info = self._get_user_profile_context(normalized_email)
        weak_areas, primary_skill = self._analyze_weak_areas(normalized_email, profile_info)

        # 2. Generate 5 fresh MCQs via Groq
        questions = self._generate_questions(primary_skill, weak_areas, profile_info)

        return {
            "skill_focus": primary_skill,
            "weak_areas": weak_areas,
            "weakness_summary": f"Targeting {', '.join(weak_areas[:2]) if weak_areas else primary_skill}",
            "questions": questions,
        }

    def _get_user_profile_context(self, email: str) -> Dict[str, Any]:
        """Fetches user's skills, target role, and experience level from users table."""
        profile_data = {
            "target_role": "Full-Stack Software Engineer",
            "skills": ["Java", "Spring Boot", "Flutter", "Microservices", "PostgreSQL"],
            "experience": "Entry-to-Mid Level",
        }
        try:
            res = self.supabase.client.table("users") \
                .select("target_role, skills, bio, years_of_experience") \
                .eq("email", email) \
                .limit(1) \
                .execute()

            if res.data and len(res.data) > 0:
                row = res.data[0]
                if row.get("target_role"):
                    profile_data["target_role"] = row["target_role"]
                if row.get("skills"):
                    s = row["skills"]
                    if isinstance(s, list):
                        profile_data["skills"] = s
                    elif isinstance(s, str):
                        profile_data["skills"] = [x.strip() for x in s.split(",") if x.strip()]
                if row.get("years_of_experience"):
                    profile_data["experience"] = f"{row['years_of_experience']} years"
        except Exception as e:
            logger.warning(f"Could not load profile context for quiz: {e}")

        return profile_data

    def _analyze_weak_areas(self, email: str, profile_info: Dict[str, Any]):
        """Pulls last 5 interview reports and identifies lowest-scoring skill categories."""
        primary_skill = profile_info.get("target_role", "Java & Spring Boot Engineer")
        user_skills = profile_info.get("skills", ["Java", "Spring Boot", "System Design"])
        weak_areas = []

        try:
            result = self.supabase.client.table("ai_interview_reports") \
                .select("target_role, feedback_summary, rubric_breakdown, overall_score") \
                .eq("candidate_email", email) \
                .order("created_at", desc=True) \
                .limit(5) \
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

        if not weak_areas:
            # Pick from user skills or defaults
            weak_areas = user_skills[:3] if len(user_skills) >= 2 else ["System Design", "Concurrency", "Database Optimization"]

        return weak_areas, primary_skill

    def _extract_weakness_keywords(self, text: str, role: str) -> List[str]:
        """Heuristic keyword extraction from feedback summaries."""
        categories = [
            "System Design & Scalability", "Concurrency & Multithreading",
            "Database Indexing & ACID", "Spring Boot & Microservices",
            "API Architecture & Resilience", "Data Structures & Algorithms",
            "Asynchronous Event Queues", "Distributed Caching & Redis",
            "Docker & Cloud Deployment", "Memory Management & Garbage Collection",
        ]
        found = [cat for cat in categories if any(word.lower() in text.lower() for word in cat.split("&")[0].split())]
        if not found:
            found = ["System Design & Scalability", "Concurrency & Multithreading", "Database Optimization"]
        return found[:3]

    def _generate_questions(self, skill: str, weak_areas: List[str], profile_info: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Calls Groq Llama-3 to generate 5 challenging, unique MCQs with explanations."""
        focus = ", ".join(weak_areas) if weak_areas else skill
        user_skills_str = ", ".join(profile_info.get("skills", []))
        random_seed_topic = random.choice([
            "real-world production incident resolution",
            "high-throughput edge case handling",
            "architectural bottleneck trade-offs",
            "memory leak & concurrency pitfall avoidance",
            "data consistency vs availability trade-off",
        ])

        prompt = f"""You are a Principal Engineering Interviewer crafting an adaptive 5-question technical MCQ skill drill.
Candidate Target Role: {skill}
Candidate Stated Skills: {user_skills_str}
Identified Weaknesses from Past Interviews: {focus}
Challenge Focus Angle: {random_seed_topic}

Generate exactly 5 distinct, high-quality Multiple Choice Questions (MCQs) that challenge the candidate's understanding in these exact weak areas.

Return ONLY a valid JSON object matching this exact schema:
{{
  "questions": [
    {{
      "id": "q1",
      "category": "Specific Technical Topic",
      "question": "Clear, practical technical scenario question?",
      "options": [
        "A. Option 1 text",
        "B. Option 2 text",
        "C. Option 3 text",
        "D. Option 4 text"
      ],
      "correct_index": 0,
      "explanation": "Detailed explanation of why this option is correct and the underlying engineering trade-offs."
    }}
  ]
}}

Guidelines:
1. Every question MUST be practical and scenario-driven, not trivia.
2. Provide exactly 4 plausible, realistic options for every question.
3. 'correct_index' MUST be an integer from 0 to 3 (0 for Option A, 1 for Option B, etc.).
4. 'explanation' MUST be thorough (2-3 sentences) explaining the engineering rationale.
5. All 5 questions must be different topics from the candidate's weak areas and skills.
6. Return purely valid JSON with no markdown wrapping."""

        try:
            raw = self.groq.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.85,
                max_tokens=2500,
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
                # Sanitize correct_index and options
                for i, q in enumerate(questions):
                    q["id"] = f"q_{i+1}"
                    if not isinstance(q.get("options"), list) or len(q["options"]) != 4:
                        q["options"] = ["Option A", "Option B", "Option C", "Option D"]
                    if not isinstance(q.get("correct_index"), int) or not (0 <= q["correct_index"] <= 3):
                        q["correct_index"] = 0
                return questions

        except Exception as e:
            logger.error(f"Groq quiz generation failed: {e}")

        # Fallback questions if Groq is temporarily unreachable
        return self._fallback_questions(skill)

    def _fallback_questions(self, skill: str) -> List[Dict[str, Any]]:
        return [
            {
                "id": "q_1",
                "category": "System Design",
                "question": f"In a high-traffic {skill} service, which rate limiting strategy allows burst traffic while strictly enforcing a fixed average rate limit?",
                "options": ["Token Bucket Algorithm", "Leaky Bucket Algorithm", "Fixed Window Counter", "Sliding Window Log"],
                "correct_index": 0,
                "explanation": "Token Bucket permits tokens to accumulate up to a maximum bucket capacity, allowing short bursts of requests while strictly throttling long-term request rates."
            },
            {
                "id": "q_2",
                "category": "Concurrency",
                "question": "Which mechanism in Java ensures memory visibility across CPU cores without the performance overhead of mutual exclusion locks?",
                "options": ["volatile keyword", "synchronized block", "ReentrantLock", "ThreadLocal storage"],
                "correct_index": 0,
                "explanation": "The volatile keyword establishes a happens-before relationship, guaranteeing that reads from all threads immediately see the most recent write without acquiring a heavy monitor lock."
            },
            {
                "id": "q_3",
                "category": "Database Architecture",
                "question": "When designing high-throughput PostgreSQL tables, why should you use Optimistic Concurrency Control (OCC) over Pessimistic Row Locking?",
                "options": [
                    "OCC eliminates row-level database locks and reduces connection wait times under high read-to-write ratios",
                    "OCC automatically retries failed database transactions at the storage engine level",
                    "OCC uses less RAM by disabling Write-Ahead Logging (WAL)",
                    "OCC prevents dirty reads without requiring transaction isolation"
                ],
                "correct_index": 0,
                "explanation": "Optimistic Locking checks a version column at commit time without holding exclusive locks during transaction execution, maximizing database throughput when write collisions are rare."
            },
            {
                "id": "q_4",
                "category": "API Resilience",
                "question": "In a Spring Boot microservice architecture, what is the primary benefit of deploying a Circuit Breaker with Resilience4j?",
                "options": [
                    "Compresses REST payload sizes over HTTP/2",
                    "Prevents cascading service failures by temporarily halting requests to an unhealthy downstream dependency",
                    "Automatically balances HTTP traffic across Kubernetes pods",
                    "Encrypts inter-service communication tokens"
                ],
                "correct_index": 1,
                "explanation": "A Circuit Breaker monitors failure rates and transitions to OPEN state when a service fails, preventing upstream thread pool exhaustion and cascading system outages."
            },
            {
                "id": "q_5",
                "category": "Distributed Caching",
                "question": "How do you effectively mitigate a Cache Stampede (Thundering Herd) when a high-traffic Redis key expires?",
                "options": [
                    "Use Mutex / Distributed Locks or probabilistic early cache recomputation (XFetch)",
                    "Increase the Redis connection pool size by 10x",
                    "Set all cache TTLs to exactly midnight",
                    "Switch from Redis to local JVM in-memory HashMap"
                ],
                "correct_index": 0,
                "explanation": "Using a distributed lock ensures only one worker thread regenerates the cache from the database, while XFetch algorithm probabilistically computes values before expiry."
            },
        ]

