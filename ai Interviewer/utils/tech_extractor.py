import re
from typing import List

# Common technologies, frameworks, tools, databases, and architectural terms to detect
TECH_KEYWORDS = [
    "React", "Vue", "Angular", "Next.js", "Nuxt", "Svelte", "Node", "Node.js", "Express",
    "Flutter", "Dart", "Swift", "Kotlin", "React Native", "iOS", "Android",
    "Python", "Java", "Go", "Golang", "Rust", "C++", "C#", ".NET", "TypeScript", "JavaScript",
    "Redis", "Kafka", "RabbitMQ", "Celery", "PostgreSQL", "MySQL", "MongoDB", "DynamoDB",
    "Cassandra", "Elasticsearch", "ELK", "Prometheus", "Grafana", "Docker", "Kubernetes",
    "K8s", "AWS", "GCP", "Azure", "Terraform", "Nginx", "GraphQL", "gRPC", "REST",
    "WebSockets", "Firebase", "Supabase", "SQL", "NoSQL", "Redux", "Zustand", "Tailwind",
    "PyTorch", "TensorFlow", "Pandas", "NumPy", "Scikit-Learn", "OpenCV", "LangChain",
    "Postman", "Git", "GitHub Actions", "CI/CD", "Spring", "Spring Boot", "FastAPI", "Django", "Flask"
]

def extract_mentioned_technologies(text: str) -> List[str]:
    """Extracts technology and tool names mentioned in candidate's response."""
    if not text:
        return []
    
    found = []
    text_lower = text.lower()
    
    for kw in TECH_KEYWORDS:
        # Use regex word boundaries for accurate matching
        pattern = r'\b' + re.escape(kw.lower()) + r'\b'
        if re.search(pattern, text_lower):
            found.append(kw)
            
    return sorted(list(set(found)))
