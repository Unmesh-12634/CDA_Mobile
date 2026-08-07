from typing import List, Optional
from pydantic import BaseModel, Field


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
    """Structured data extracted from candidate resume or manual input."""

    name: str = Field(default="Candidate")
    experience_level: str = Field(default="Mid-Level", description="Options: Entry-Level, Mid-Level, Senior, Lead/Architect")
    target_career_goal: str = Field(default="", description="Candidate's career objective or target role level")
    education: List[str] = Field(default_factory=list)
    skills: List[str] = Field(default_factory=list)
    programming_languages: List[str] = Field(default_factory=list)
    frameworks: List[str] = Field(default_factory=list)
    databases: List[str] = Field(default_factory=list)
    tools: List[str] = Field(default_factory=list)
    projects: List[ProjectInfo] = Field(default_factory=list)
    internships: List[WorkExperience] = Field(default_factory=list)
    work_experience: List[WorkExperience] = Field(default_factory=list)
    certifications: List[str] = Field(default_factory=list)
    achievements: List[str] = Field(default_factory=list)
    domains: List[str] = Field(default_factory=list)
    summary: str = Field(default="Profile initialized.")
    has_resume: bool = Field(default=False)

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
        """Builds a rich, compact candidate context string for prompt framing."""
        lines = [
            f"Candidate Name: {self.name}",
            f"Experience Seniority Level: {self.experience_level}",
            f"Target Career Goal: {self.target_career_goal if self.target_career_goal else 'Growth in selected job role'}",
        ]

        if self.programming_languages:
            lines.append(f"Programming Languages: {', '.join(self.programming_languages[:8])}")
        if self.frameworks:
            lines.append(f"Frameworks & Libraries: {', '.join(self.frameworks[:8])}")
        if self.databases:
            lines.append(f"Databases & Storage: {', '.join(self.databases[:5])}")
        if self.tools:
            lines.append(f"Tools & Platforms: {', '.join(self.tools[:8])}")
        if self.skills:
            lines.append(f"General Core Skills: {', '.join(self.skills[:12])}")

        if self.projects:
            lines.append("\nCandidate Projects (Reference for Deep-Dive Questions):")
            for idx, p in enumerate(self.projects[:4], 1):
                tech_str = f" [Tech: {', '.join(p.technologies[:4])}]" if p.technologies else ""
                desc_str = f" - {p.description[:120]}" if p.description else ""
                lines.append(f"  {idx}. {p.title}{tech_str}{desc_str}")

        if self.work_experience or self.internships:
            lines.append("\nWork & Internship Experience:")
            for e in (self.work_experience + self.internships)[:3]:
                dur = f" ({e.duration})" if e.duration else ""
                lines.append(f"  • {e.role} at {e.company}{dur}")

        if self.certifications:
            lines.append(f"Certifications: {', '.join(self.certifications[:3])}")

        return "\n".join(lines)
