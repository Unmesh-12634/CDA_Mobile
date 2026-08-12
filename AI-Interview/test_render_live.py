import json
import urllib.request
import urllib.error

url = "https://cda-ai-interview-engine.onrender.com/api/v1/interview/start"
payload = {
    "candidate_name": "Arjun",
    "job_role": "Software Engineer",
    "experience_level": "Mid-Level",
    "interview_type": "Technical",
    "difficulty": "Intermediate",
    "target_question_count": 5,
    "voice_persona": "guy"
}

req = urllib.request.Request(
    url,
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"}
)

try:
    res = urllib.request.urlopen(req)
    print("STATUS:", res.getcode())
    print("BODY:", res.read().decode("utf-8"))
except urllib.error.HTTPError as e:
    print("HTTP ERROR CODE:", e.code)
    print("HTTP ERROR BODY:", e.read().decode("utf-8"))
except Exception as e:
    print("ERROR:", e)
