"""
CDA Learning Recommendation Engine
Analyzes AI Interview Reports and generates targeted learning recommendations
mapping candidate weak competencies to actual CDA courses, video modules, and website lessons.
"""

import logging
from typing import List, Dict, Any
from models.interview import InterviewReport
from services.supabase_service import SupabaseRepository

logger = logging.getLogger("recommendation_service")

# CDA Official Target Course URL
TARGET_COURSE_URL = "https://www.youtube.com/watch?v=Uf6PXnagtsg"

# CDA Official Fallback Course Registry (aligned with public.cda_courses)
FALLBACK_CDA_COURSES = [
    {
        "course_id": "c0000000-0000-0000-0000-000000000001",
        "title": "Full-Stack Java Enterprise & Microservices Masterclass",
        "category": "Java & Backend",
        "keywords": ["java", "spring boot", "microservices", "kafka", "hibernate", "jpa", "concurrency", "multithreading", "jvm", "postgres", "sql"],
        "tags": ["#Java", "#SpringBoot", "#Microservices", "#Kafka", "#PostgreSQL", "#SystemDesign"],
        "cda_learning_url": TARGET_COURSE_URL,
        "estimated_duration": "12 Weeks",
        "badge": "CDA Java Master",
    },
    {
        "course_id": "c0000000-0000-0000-0000-000000000002",
        "title": "System Design & Distributed High-Throughput Architecture",
        "category": "System Design",
        "keywords": ["system design", "distributed", "scalability", "redis", "caching", "sharding", "load balancing", "kafka", "architecture", "microservices"],
        "tags": ["#SystemDesign", "#DistributedSystems", "#Scalability", "#Redis", "#AWS", "#Microservices"],
        "cda_learning_url": TARGET_COURSE_URL,
        "estimated_duration": "8 Weeks",
        "badge": "CDA Systems Architect",
    },
    {
        "course_id": "c0000000-0000-0000-0000-000000000003",
        "title": "Python AI, Deep Learning & Generative AI Engineering",
        "category": "AI & Data Science",
        "keywords": ["python", "ai", "machine learning", "ml", "deep learning", "pytorch", "transformers", "llm", "genai", "langchain", "rag", "numpy", "pandas"],
        "tags": ["#Python", "#MachineLearning", "#PyTorch", "#GenAI", "#LangChain", "#LLMs"],
        "cda_learning_url": TARGET_COURSE_URL,
        "estimated_duration": "14 Weeks",
        "badge": "CDA AI Engineer",
    },
    {
        "course_id": "c0000000-0000-0000-0000-000000000004",
        "title": "Embedded Systems, RTOS & Automotive IoT Architecture",
        "category": "Embedded & IoT",
        "keywords": ["embedded", "c", "rtos", "arm", "microcontroller", "can bus", "iot", "firmware", "hardware", "automotive"],
        "tags": ["#EmbeddedC", "#RTOS", "#ARMCortex", "#IoT", "#Automotive", "#Firmware"],
        "cda_learning_url": TARGET_COURSE_URL,
        "estimated_duration": "16 Weeks",
        "badge": "CDA Embedded Master",
    },
    {
        "course_id": "c0000000-0000-0000-0000-000000000005",
        "title": "Modern Cross-Platform Flutter & Clean Architecture",
        "category": "Mobile Development",
        "keywords": ["flutter", "dart", "riverpod", "state management", "mobile", "ios", "android", "clean architecture", "widgets", "animations"],
        "tags": ["#Flutter", "#Dart", "#Riverpod", "#CleanArchitecture", "#MobileDev", "#iOSAndroid"],
        "cda_learning_url": TARGET_COURSE_URL,
        "estimated_duration": "8 Weeks",
        "badge": "CDA Mobile Architect",
    },
    {
        "course_id": "c0000000-0000-0000-0000-000000000006",
        "title": "Cloud DevOps, Docker & Kubernetes Production Engineering",
        "category": "DevOps & Cloud",
        "keywords": ["devops", "docker", "kubernetes", "k8s", "aws", "ci/cd", "terraform", "cloud", "helm", "linux", "deployment"],
        "tags": ["#DevOps", "#Kubernetes", "#Docker", "#AWS", "#CI_CD", "#Terraform"],
        "cda_learning_url": TARGET_COURSE_URL,
        "estimated_duration": "10 Weeks",
        "badge": "CDA DevOps Specialist",
    },
]


class RecommendationService:
    """Matches identified candidate weak competencies to concrete CDA courses stored in database."""

    def __init__(self):
        self.supabase = SupabaseRepository()

    def _fetch_db_courses(self) -> List[Dict[str, Any]]:
        """Attempts to fetch active courses from Supabase cda_courses table with fallback."""
        try:
            res = self.supabase.client.table("cda_courses").select("*").eq("is_active", True).execute()
            if res.data and len(res.data) > 0:
                courses = []
                for row in res.data:
                    courses.append({
                        "course_id": row.get("id"),
                        "title": row.get("title"),
                        "category": row.get("category"),
                        "description": row.get("description", ""),
                        "keywords": [t.replace("#", "").lower() for t in (row.get("tags") or [])] + [row.get("category", "").lower()],
                        "tags": row.get("tags") or ["#CDA", "#TechMastery"],
                        "cda_learning_url": row.get("link_url") or TARGET_COURSE_URL,
                        "estimated_duration": row.get("estimated_duration") or "10 Weeks",
                        "badge": f"CDA {row.get('category')} Specialist",
                    })
                return courses
        except Exception as e:
            logger.warning(f"Could not load courses from Supabase cda_courses table: {e}")

        return FALLBACK_CDA_COURSES

    def generate_recommendations(self, report: InterviewReport) -> List[Dict[str, Any]]:
        courses = self._fetch_db_courses()
        weak_topics = set()

        # Collect weak areas and missing concepts
        for area in report.areas_for_improvement:
            weak_topics.add(area.lower())
        for topic in report.recommended_topics_to_study:
            weak_topics.add(topic.lower())

        for review in report.question_reviews:
            for missing in review.missing_concepts:
                weak_topics.add(missing.lower())
            for inc in review.incorrect_points:
                weak_topics.add(inc.lower())

        # Match weak topics against CDA Course Registry
        matched_courses = []
        for course in courses:
            score = 0
            matching_reasons = []
            for kw in course["keywords"]:
                for weak in weak_topics:
                    if kw in weak or weak in kw:
                        score += 1
                        matching_reasons.append(weak.title())

            if score > 0 or course["category"].lower() in report.job_role.lower():
                matched_courses.append({
                    "course_id": course["course_id"],
                    "title": course["title"],
                    "category": course["category"],
                    "reason": f"Targeted practice for identified: {', '.join(set(matching_reasons[:2]))}" if matching_reasons else f"Essential core foundation for {report.job_role}",
                    "priority": "HIGH" if score >= 2 else "MEDIUM",
                    "cda_learning_url": course["cda_learning_url"],
                    "estimated_duration": course["estimated_duration"],
                    "tags": course.get("tags", []),
                    "badge": course.get("badge", "CDA Certified"),
                })

        # Sort by priority
        matched_courses.sort(key=lambda x: 0 if x["priority"] == "HIGH" else 1)

        # Fallback if no specific course matched
        if not matched_courses:
            first = courses[0] if courses else FALLBACK_CDA_COURSES[0]
            matched_courses.append({
                "course_id": first["course_id"],
                "title": first["title"],
                "category": first["category"],
                "reason": f"Recommended production engineering foundation for {report.job_role}",
                "priority": "HIGH",
                "cda_learning_url": first.get("cda_learning_url", TARGET_COURSE_URL),
                "estimated_duration": first.get("estimated_duration", "12 Weeks"),
                "tags": first.get("tags", ["#CDA", "#CareerReady"]),
                "badge": first.get("badge", "CDA Certified"),
            })

        return matched_courses[:3]
