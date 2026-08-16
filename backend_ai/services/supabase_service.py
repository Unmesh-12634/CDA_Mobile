import os
import json
import logging
from typing import Dict, List, Optional, Any
import requests

logger = logging.getLogger("supabase_repository")

class SupabaseRepository:
    """Centralized repository layer for Supabase PostgreSQL REST API operations."""

    def __init__(self, supabase_url: Optional[str] = None, supabase_key: Optional[str] = None):
        self.url = (supabase_url or os.getenv("SUPABASE_URL") or "https://jbauuvxeybakihedeskj.supabase.co").rstrip('/')
        self.key = (
            supabase_key 
            or os.getenv("SUPABASE_ANON_KEY") 
            or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiYXV1dnhleWJha2loZWRlc2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5MDMxNTgsImV4cCI6MjEwMDQ3OTE1OH0.FBLtZxjOt8UG-W1vUw67V43D3mB22UhPBKSltqj2dTg"
        )
        self.headers = {
            "apikey": self.key,
            "Authorization": f"Bearer {self.key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    # ─────────────────────────────────────────────────────────────
    # 1. Interview Blocks (JDs) DB Operations
    # ─────────────────────────────────────────────────────────────

    def get_all_interview_blocks(self) -> List[Dict[str, Any]]:
        """Fetches all active interview JD blocks from Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/interview_blocks?is_active=eq.true&order=created_at.desc"
            res = requests.get(endpoint, headers=self.headers, timeout=10)
            if res.status_code == 200:
                return res.json()
            logger.error(f"Supabase error fetching blocks: {res.status_code} - {res.text}")
        except Exception as e:
            logger.exception(f"Failed to fetch interview blocks from Supabase DB: {e}")
        return []

    def get_interview_block(self, block_id: str) -> Optional[Dict[str, Any]]:
        """Fetches a specific interview block by ID or title match."""
        try:
            # Try UUID or title match
            endpoint = f"{self.url}/rest/v1/interview_blocks?or=(id.eq.{block_id},title.ilike.*{block_id}*)&limit=1"
            res = requests.get(endpoint, headers=self.headers, timeout=10)
            if res.status_code == 200:
                data = res.json()
                if data:
                    return data[0]
        except Exception as e:
            logger.exception(f"Failed to fetch interview block '{block_id}': {e}")
        return None

    def create_interview_block(self, block_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Creates a new JD block in Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/interview_blocks"
            payload = {k: v for k, v in block_data.items() if k != 'id' and v is not None}
            res = requests.post(endpoint, headers=self.headers, json=payload, timeout=10)
            if res.status_code in (200, 201):
                data = res.json()
                return data[0] if isinstance(data, list) and data else data
            logger.error(f"Failed to create interview block in DB: {res.status_code} - {res.text}")
        except Exception as e:
            logger.exception(f"Error creating interview block in Supabase: {e}")
        return None

    def delete_interview_block(self, block_id: str) -> bool:
        """Deactivates an interview block in Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/interview_blocks?id=eq.{block_id}"
            res = requests.patch(endpoint, headers=self.headers, json={"is_active": False}, timeout=10)
            return res.status_code in (200, 204)
        except Exception as e:
            logger.exception(f"Error deleting interview block '{block_id}': {e}")
            return False

    # ─────────────────────────────────────────────────────────────
    # 2. Evaluation Rubrics DB Operations
    # ─────────────────────────────────────────────────────────────

    def get_rubric_for_role(self, job_role: str) -> Dict[str, Any]:
        """Fetches matching evaluation rubric from Supabase DB or default rubric."""
        try:
            endpoint = f"{self.url}/rest/v1/interview_rubrics?order=is_default.asc"
            res = requests.get(endpoint, headers=self.headers, timeout=10)
            if res.status_code == 200:
                rubrics = res.json()
                if rubrics:
                    # Match role category or return default
                    role_lower = job_role.lower()
                    for r in rubrics:
                        cat = (r.get('role_category') or '').lower()
                        name = (r.get('rubric_name') or '').lower()
                        if cat and (cat in role_lower or role_lower in cat or name in role_lower):
                            return r
                    # Fallback to default rubric in list
                    for r in rubrics:
                        if r.get('is_default'):
                            return r
                    return rubrics[0]
        except Exception as e:
            logger.exception(f"Error fetching rubric for role '{job_role}': {e}")

        # Basic fallback schema if network is disconnected
        return {
            "rubric_name": "Standard Software Engineering Rubric",
            "technical_weight": 0.35,
            "communication_weight": 0.20,
            "problem_solving_weight": 0.25,
            "architecture_weight": 0.10,
            "role_readiness_weight": 0.10,
            "scoring_instructions": "Evaluate correctness, technical depth, reasoning, and clarity.",
        }

    # ─────────────────────────────────────────────────────────────
    # 3. Session Lifecycle & State DB Operations
    # ─────────────────────────────────────────────────────────────

    def get_all_sessions(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Fetches all recent interview sessions from Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/ai_interview_session?order=updated_at.desc&limit={limit}"
            res = requests.get(endpoint, headers=self.headers, timeout=10)
            if res.status_code == 200:
                return res.json()
            logger.error(f"Error fetching sessions: {res.status_code} - {res.text}")
        except Exception as e:
            logger.exception(f"Failed to fetch sessions from Supabase: {e}")
        return []

    def get_all_reports(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Fetches all recent interview reports from Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/ai_interview_reports?order=created_at.desc&limit={limit}"
            res = requests.get(endpoint, headers=self.headers, timeout=10)
            if res.status_code == 200:
                return res.json()
            logger.error(f"Error fetching reports: {res.status_code} - {res.text}")
        except Exception as e:
            logger.exception(f"Failed to fetch reports from Supabase: {e}")
        return []

    def create_session(self, session_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Persists a new interview session state in Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/ai_interview_session"
            res = requests.post(endpoint, headers=self.headers, json=session_data, timeout=10)
            if res.status_code in (200, 201):
                data = res.json()
                return data[0] if isinstance(data, list) and data else data
            logger.error(f"Failed to create session in Supabase DB: {res.status_code} - {res.text}")
        except Exception as e:
            logger.exception(f"Error creating session in DB: {e}")
        return None

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves session state from Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/ai_interview_session?session_id=eq.{session_id}&limit=1"
            res = requests.get(endpoint, headers=self.headers, timeout=10)
            if res.status_code == 200:
                data = res.json()
                if data:
                    return data[0]
        except Exception as e:
            logger.exception(f"Error fetching session '{session_id}' from DB: {e}")
        return None

    def update_session(self, session_id: str, update_data: Dict[str, Any]) -> bool:
        """Updates session state in Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/ai_interview_session?session_id=eq.{session_id}"
            res = requests.patch(endpoint, headers=self.headers, json=update_data, timeout=10)
            return res.status_code in (200, 204)
        except Exception as e:
            logger.exception(f"Error updating session '{session_id}' in DB: {e}")
            return False

    # ─────────────────────────────────────────────────────────────
    # 4. Final Reports DB Operations
    # ─────────────────────────────────────────────────────────────

    def save_report(self, report_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Saves final evaluation report to Supabase DB."""
        try:
            endpoint = f"{self.url}/rest/v1/ai_interview_reports"
            res = requests.post(endpoint, headers=self.headers, json=report_data, timeout=10)
            if res.status_code in (200, 201):
                data = res.json()
                return data[0] if isinstance(data, list) and data else data
            logger.error(f"Failed to save report in DB: {res.status_code} - {res.text}")
        except Exception as e:
            logger.exception(f"Error saving report in DB: {e}")
        return None
