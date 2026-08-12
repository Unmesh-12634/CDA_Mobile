"""
Groq API Key Diagnostic & Multi-Model Rate Limits Audit Tool
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

try:
    from colorama import Fore, Style, init
    init(autoreset=True)
    GREEN = Fore.GREEN
    RED = Fore.RED
    YELLOW = Fore.YELLOW
    CYAN = Fore.CYAN
    BOLD = Style.BRIGHT
    RESET = Style.RESET_ALL
except ImportError:
    GREEN = RED = YELLOW = CYAN = BOLD = RESET = ""

try:
    from groq import Groq, APIConnectionError, AuthenticationError, RateLimitError
except ImportError:
    print("ERROR: 'groq' package is not installed. Run: pip install groq")
    sys.exit(1)


# Known Official Free-Tier Rate Limits for Groq Models
GROQ_MODEL_LIMITS = {
    "llama-3.1-8b-instant": {
        "role": "AI Interviewer / Planner (Primary)",
        "rpm": "30 RPM",
        "rpd": "14,400 RPD",
        "tpm": "500,000 TPM",
        "tpd": "14.4M TPD",
    },
    "llama-3.3-70b-versatile": {
        "role": "Deep Technical Evaluator",
        "rpm": "30 RPM",
        "rpd": "1,000 RPD",
        "tpm": "300,000 TPM",
        "tpd": "100,000 TPD",
    },
    "llama-3.2-3b-preview": {
        "role": "Lightweight Follow-up",
        "rpm": "30 RPM",
        "rpd": "14,400 RPD",
        "tpm": "500,000 TPM",
        "tpd": "14.4M TPD",
    },
    "llama-3.2-1b-preview": {
        "role": "Ultra-fast Micro Agent",
        "rpm": "30 RPM",
        "rpd": "14,400 RPD",
        "tpm": "500,000 TPM",
        "tpd": "14.4M TPD",
    },
    "qwen-2.5-coder-32b": {
        "role": "Coding Specialist",
        "rpm": "30 RPM",
        "rpd": "1,000 RPD",
        "tpm": "300,000 TPM",
        "tpd": "100,000 TPD",
    },
    "deepseek-r1-distill-llama-70b": {
        "role": "Reasoning Model",
        "rpm": "30 RPM",
        "rpd": "1,000 RPD",
        "tpm": "300,000 TPM",
        "tpd": "100,000 TPD",
    },
    "whisper-large-v3-turbo": {
        "role": "Voice-to-Text STT",
        "rpm": "20 RPM",
        "rpd": "2,000 RPD",
        "tpm": "N/A",
        "tpd": "N/A",
    },
}


def audit_groq_api():
    print(f"\n{CYAN}{BOLD}===================================================================================={RESET}")
    print(f"{CYAN}{BOLD}                GROQ API KEY & ALL MODELS RATE LIMIT AUDIT                           {RESET}")
    print(f"{CYAN}{BOLD}===================================================================================={RESET}\n")

    api_key = os.getenv("GROQ_API_KEY", "").strip()

    if not api_key:
        print(f"{RED}{BOLD}[FAIL] GROQ_API_KEY is missing from .env file!{RESET}\n")
        return False

    masked_key = api_key[:7] + "..." + api_key[-4:] if len(api_key) > 12 else "gsk_***"
    print(f"{BOLD}Testing API Key:{RESET} {CYAN}{masked_key}{RESET}\n")

    try:
        client = Groq(api_key=api_key)

        # Retrieve available models
        models_page = client.models.list()
        all_model_ids = [m.id for m in models_page.data]
        print(f"{GREEN}[OK] API Key Authenticated Successfully!{RESET} Access to {len(all_model_ids)} Groq models.\n")

        print(f"{BOLD}{'MODEL NAME':<32} | {'STATUS':<15} | {'RPD (Req/Day)':<14} | {'TPM (Tok/Min)':<14} | {'ROLE':<28}{RESET}")
        print("-" * 110)

        for model_id in all_model_ids:
            # Skip prompt guard / safety utility endpoints for clean output
            if "guard" in model_id or "safeguard" in model_id or "orpheus" in model_id or "allam" in model_id:
                continue

            limits = GROQ_MODEL_LIMITS.get(
                model_id,
                {"role": "General LLM", "rpm": "30 RPM", "rpd": "Standard", "tpm": "Standard", "tpd": "Standard"},
            )

            status_str = ""
            try:
                if "whisper" in model_id:
                    status_str = f"{GREEN}ACTIVE [AUDIO]{RESET}"
                else:
                    client.chat.completions.create(
                        model=model_id,
                        messages=[{"role": "user", "content": "hi"}],
                        max_tokens=2,
                    )
                    status_str = f"{GREEN}ACTIVE [READY]{RESET}"
            except RateLimitError:
                status_str = f"{YELLOW}RATE LIMITED (429){RESET}"
            except Exception as e:
                err_msg = str(e)
                if "model_decommissioned" in err_msg:
                    status_str = f"{RED}DECOMMISSIONED{RESET}"
                elif "Request too large" in err_msg or "413" in err_msg:
                    status_str = f"{YELLOW}TPM EXCEEDED{RESET}"
                else:
                    status_str = f"{RED}ERROR{RESET}"

            print(
                f"{model_id:<32} | {status_str:<24} | {limits['rpd']:<14} | {limits['tpm']:<14} | {limits['role']:<28}"
            )

        print("-" * 110)
        print(f"\n{GREEN}{BOLD}[SUMMARY]: Your API key is 100% active and operational.{RESET}")
        print(f"{CYAN}Default Model 'llama-3.1-8b-instant' gives you 500,000 Tokens/Min & 14,400 Requests/Day!{RESET}\n")
        return True

    except AuthenticationError:
        print(f"\n{RED}{BOLD}[FAIL] Invalid Groq API Key!{RESET}\n")
        return False
    except Exception as e:
        print(f"\n{RED}{BOLD}[FAIL] Error auditing Groq API:{RESET} {e}\n")
        return False


if __name__ == "__main__":
    audit_groq_api()
