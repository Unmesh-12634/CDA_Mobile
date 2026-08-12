import os
import sys
from pathlib import Path
from groq import Groq
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

api_key = os.getenv("GROQ_API_KEY", "")

if not api_key:
    print("ERROR: GROQ_API_KEY is missing.")
    sys.exit(1)

client = Groq(api_key=api_key)

print("\n=========================================")
print("       GROQ MODELS & RATE LIMIT AUDIT     ")
print("=========================================\n")

try:
    models_page = client.models.list()
    available_models = [m.id for m in models_page.data]
    print(f"Total Available Models on Groq API: {len(available_models)}\n")

    for model_id in available_models:
        try:
            response = client.chat.completions.create(
                model=model_id,
                messages=[{"role": "user", "content": "Hi"}],
                max_tokens=2,
            )
            print(f"[ACTIVE]        Model: {model_id:<32} -> READY TO USE")
        except Exception as e:
            err_msg = str(e)
            if "rate_limit_exceeded" in err_msg or "429" in err_msg:
                print(f"[RATE LIMITED]  Model: {model_id:<32} -> Daily Token Limit Reached")
            elif "model_decommissioned" in err_msg or "400" in err_msg:
                print(f"[DECOMMISSIONED] Model: {model_id:<32} -> Deprecated by Groq")
            elif "Request too large" in err_msg or "413" in err_msg:
                print(f"[TPM EXCEEDED]  Model: {model_id:<32} -> Token Per Minute Cap")
            else:
                clean_err = err_msg.replace('\n', ' ')[:55]
                print(f"[ERROR]         Model: {model_id:<32} -> {clean_err}")

except Exception as e:
    print(f"Error querying Groq models: {e}")
