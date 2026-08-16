"""
CDA Learning Recommendation Engine
Analyzes AI Interview Reports and generates targeted learning recommendations
mapping candidate weak competencies to actual CDA courses and website lessons.
"""

from typing import List, Dict, Any
from models.interview import InterviewReport


# CDA Official Course & Lesson Registry Map
CDA_COURSE_REGISTRY = [
    {
        "course_id": "cda-py-101",
        "title": "Python Architecture, Memory & Multithreading",
        "category": "Python",
        "keywords": ["python", "asyncio", "gil", "concurrency", "multithreading", "memory", "decorators", "generators"],
        "cda_learning_url": "https://cranesdigitalacademy.com/courses/python-mastery",
        "estimated_duration": "4.5 Hours",
        "badge": "CDA Certified Python Specialist",
    },
    {
        "course_id": "cda-java-201",
        "title": "Java Spring Boot Microservices & Production JVM Tuning",
        "category": "Java",
        "keywords": ["java", "spring boot", "jvm", "garbage collection", "hibernate", "jpa", "concurrency", "maven"],
        "cda_learning_url": "https://cranesdigitalacademy.com/courses/java-spring-boot",
        "estimated_duration": "6.0 Hours",
        "badge": "CDA Spring Boot Master",
    },
    {
        "course_id": "cda-flt-301",
        "title": "Advanced Flutter State Management, Riverpod & Performance",
        "category": "Flutter",
        "keywords": ["flutter", "dart", "riverpod", "state management", "widget tree", "isolates", "animations"],
        "cda_learning_url": "https://cranesdigitalacademy.com/courses/flutter-advanced",
        "estimated_duration": "5.0 Hours",
        "badge": "CDA Mobile Architect",
    },
    {
        "course_id": "cda-sys-401",
        "title": "System Design: Microservices, Distributed Caching & Sharding",
        "category": "System Design",
        "keywords": ["system design", "microservices", "redis", "caching", "kafka", "database sharding", "load balancing", "api gateway"],
        "cda_learning_url": "https://cranesdigitalacademy.com/courses/system-design-microservices",
        "estimated_duration": "8.0 Hours",
        "badge": "CDA Systems Architect",
    },
    {
        "course_id": "cda-react-501",
        "title": "React 19 & Next.js App Router Masterclass",
        "category": "React",
        "keywords": ["react", "next.js", "javascript", "typescript", "ssr", "server components", "redux", "state"],
        "cda_learning_url": "https://cranesdigitalacademy.com/courses/react-nextjs",
        "estimated_duration": "5.5 Hours",
        "badge": "CDA Frontend Expert",
    },
    {
        "course_id": "cda-aiml-601",
        "title": "Applied AI & LLM Fine-Tuning with Python & PyTorch",
        "category": "AI/ML",
        "keywords": ["ai", "machine learning", "ml", "deep learning", "pytorch", "transformers", "llm", "embeddings", "rag"],
        "cda_learning_url": "https://cranesdigitalacademy.com/courses/ai-ml-fundamentals",
        "estimated_duration": "7.0 Hours",
        "badge": "CDA AI Engineer",
    },
]


class RecommendationService:
    """Matches identified candidate weak competencies to concrete CDA learning paths."""

    def generate_recommendations(self, report: InterviewReport) -> List[Dict[str, Any]]:
        recommendations = []
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
        for course in CDA_COURSE_REGISTRY:
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
                    "reason": f"Identified gap in: {', '.join(set(matching_reasons[:3]))}" if matching_reasons else f"Essential core foundation for {report.job_role}",
                    "priority": "HIGH" if score >= 2 else "MEDIUM",
                    "cda_learning_url": course["cda_learning_url"],
                    "estimated_duration": course["estimated_duration"],
                    "badge": course["badge"],
                })

        # Sort by priority
        matched_courses.sort(key=lambda x: 0 if x["priority"] == "HIGH" else 1)

        # Fallback if no specific course matched
        if not matched_courses:
            matched_courses.append({
                "course_id": "cda-sys-401",
                "title": "System Design: Microservices, Distributed Caching & Sharding",
                "category": "System Design",
                "reason": f"Recommended production engineering foundation for {report.job_role}",
                "priority": "HIGH",
                "cda_learning_url": "https://cranesdigitalacademy.com/courses/system-design-microservices",
                "estimated_duration": "8.0 Hours",
                "badge": "CDA Systems Architect",
            })

        return matched_courses[:3]
