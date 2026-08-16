from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field, field_validator


class ProjectInfo(BaseModel):
    """Details about a candidate project."""
    title: str = Field(default="Unnamed Project")
    description: str = Field(default="")
    technologies: List[str] = Field(default_factory=list)
    role: Optional[str] = None


class WorkExperience(BaseModel):
    """Details about candidate work or internship experience."""
    company: str = Field(default="Unknown Company")
    role: str = Field(default="Contributor")
    duration: Optional[str] = None
    highlights: List[str] = Field(default_factory=list)


class CandidateProfile(BaseModel):
    """360-Degree structured profile data extracted from candidate resume or manual input."""

    name: str = Field(default="Candidate")
    about_me: str = Field(default="", description="Summary, objective, or about section from resume")
    experience_level: str = Field(default="Mid-Level", description="Options: Entry-Level, Mid-Level, Senior, Lead/Architect")
    target_career_goal: str = Field(default="", description="Candidate's career objective or target role level")
    education: List[str] = Field(default_factory=list)
    skills: List[str] = Field(default_factory=list)
    programming_languages: List[str] = Field(default_factory=list)
    frameworks: List[str] = Field(default_factory=list)
    libraries: List[str] = Field(default_factory=list)
    databases: List[str] = Field(default_factory=list)
    tools: List[str] = Field(default_factory=list)
    cloud_platforms: List[str] = Field(default_factory=list)
    ai_skills: List[str] = Field(default_factory=list)
    projects: List[ProjectInfo] = Field(default_factory=list)
    internships: List[WorkExperience] = Field(default_factory=list)
    work_experience: List[WorkExperience] = Field(default_factory=list)
    certifications: List[str] = Field(default_factory=list)
    courses: List[str] = Field(default_factory=list)
    research_publications: List[str] = Field(default_factory=list)
    hackathons: List[str] = Field(default_factory=list)
    open_source_contributions: List[str] = Field(default_factory=list)
    leadership_roles: List[str] = Field(default_factory=list)
    campus_activities: List[str] = Field(default_factory=list)
    achievements: List[str] = Field(default_factory=list)
    awards: List[str] = Field(default_factory=list)
    github_projects: List[str] = Field(default_factory=list)
    portfolio_url: str = Field(default="")

    @field_validator(
        "hackathons", "certifications", "courses", "achievements", "awards",
        "education", "skills", "tools", "libraries", "programming_languages",
        "frameworks", "databases", "cloud_platforms", "ai_skills", "leadership_roles",
        "campus_activities", "open_source_contributions", "research_publications",
        "github_projects", "domains", mode="before"
    )
    @classmethod
    def coerce_to_string_list(cls, v: Any) -> List[str]:
        if not v:
            return []
        if isinstance(v, list):
            result = []
            for item in v:
                if isinstance(item, str):
                    result.append(item)
                elif isinstance(item, dict):
                    name = (
                        item.get("name")
                        or item.get("title")
                        or item.get("role")
                        or item.get("hackathon")
                        or item.get("cert")
                        or item.get("publication")
                        or str(item)
                    )
                    achieve = (
                        item.get("achievement")
                        or item.get("details")
                        or item.get("description")
                        or item.get("organization")
                        or ""
                    )
                    combined = f"{name} - {achieve}" if achieve else str(name)
                    result.append(combined)
                else:
                    result.append(str(item))
            return result
        return [str(v)]
    domains: List[str] = Field(default_factory=list)
    summary: str = Field(default="Profile initialized.")
    has_resume: bool = Field(default=False)
    raw_resume_text: str = Field(default="")

    def to_brief_summary(self) -> str:
        """Generates a concise string summary for LLM prompt contexts."""
        parts = [f"Name: {self.name}", f"Level: {self.experience_level}"]
        if self.target_career_goal:
            parts.append(f"Goal: {self.target_career_goal}")
        if self.skills:
            parts.append(f"Top Skills: {', '.join(self.skills[:10])}")
        if self.programming_languages:
            parts.append(f"Languages: {', '.join(self.programming_languages[:6])}")
        if self.frameworks:
            parts.append(f"Frameworks: {', '.join(self.frameworks[:6])}")
        if self.databases:
            parts.append(f"Databases: {', '.join(self.databases[:4])}")
        if self.projects:
            proj_str = "; ".join([f"{p.title} ({', '.join(p.technologies[:3])})" for p in self.projects[:3]])
            parts.append(f"Projects: {proj_str}")
        if self.work_experience or self.internships:
            exp_list = self.work_experience + self.internships
            exp_str = "; ".join([f"{e.role} at {e.company}" for e in exp_list[:2]])
            parts.append(f"Experience: {exp_str}")

        return " | ".join(parts)

    def to_detailed_prompt_context(self) -> str:
        """Builds a 360-degree, complete candidate context string for prompt framing."""
        lines = [
            f"Candidate Name: {self.name}",
            f"Seniority Level: {self.experience_level}",
        ]
        if self.about_me:
            lines.append(f"Summary / About Me: {self.about_me}")
        if self.target_career_goal:
            lines.append(f"Target Career Goal: {self.target_career_goal}")

        if self.programming_languages:
            lines.append(f"Programming Languages: {', '.join(self.programming_languages)}")
        if self.frameworks:
            lines.append(f"Frameworks & Web Stack: {', '.join(self.frameworks)}")
        if self.libraries:
            lines.append(f"Libraries & Packages: {', '.join(self.libraries)}")
        if self.databases:
            lines.append(f"Databases & Storage: {', '.join(self.databases)}")
        if self.tools:
            lines.append(f"DevOps & Tools: {', '.join(self.tools)}")
        if self.cloud_platforms:
            lines.append(f"Cloud Platforms: {', '.join(self.cloud_platforms)}")
        if self.ai_skills:
            lines.append(f"AI & ML Stack: {', '.join(self.ai_skills)}")
        if self.skills:
            lines.append(f"All Technical Skills: {', '.join(self.skills)}")

        if self.projects:
            lines.append("\nALL CANDIDATE PROJECTS (Must explore multiple across interview):")
            for idx, p in enumerate(self.projects, 1):
                tech_str = f" [Tech: {', '.join(p.technologies)}]" if p.technologies else ""
                desc_str = f" - {p.description[:200]}" if p.description else ""
                lines.append(f"  Project #{idx}: {p.title}{tech_str}{desc_str}")

        if self.work_experience or self.internships:
            lines.append("\nWork & Internship Experience:")
            for e in (self.work_experience + self.internships):
                dur = f" ({e.duration})" if e.duration else ""
                lines.append(f"  • {e.role} at {e.company}{dur}")

        if self.hackathons:
            lines.append(f"\nHackathons & Competitions: {', '.join(self.hackathons)}")
        if self.certifications:
            lines.append(f"Certifications: {', '.join(self.certifications)}")
        if self.courses:
            lines.append(f"Courses & Certs: {', '.join(self.courses)}")
        if self.research_publications:
            lines.append(f"Research & Publications: {', '.join(self.research_publications)}")
        if self.open_source_contributions:
            lines.append(f"Open Source Contributions: {', '.join(self.open_source_contributions)}")
        if self.leadership_roles or self.campus_activities:
            lines.append(f"Leadership & Extracurriculars: {', '.join(self.leadership_roles + self.campus_activities)}")
        if self.achievements or self.awards:
            lines.append(f"Achievements & Awards: {', '.join(self.achievements + self.awards)}")
        if self.education:
            lines.append(f"Education: {', '.join(self.education)}")

        return "\n".join(lines)
