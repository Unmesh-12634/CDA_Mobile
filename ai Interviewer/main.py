import os
import sys
from pathlib import Path
from typing import Optional

try:
    from colorama import Fore, Style, init
    init(autoreset=True)
    CYAN = Fore.CYAN
    GREEN = Fore.GREEN
    YELLOW = Fore.YELLOW
    RED = Fore.RED
    MAGENTA = Fore.MAGENTA
    BOLD = Style.BRIGHT
    RESET = Style.RESET_ALL
except ImportError:
    CYAN = GREEN = YELLOW = RED = MAGENTA = BOLD = RESET = ""

from config.settings import settings
from models.interview import DifficultyLevel, InterviewConfig, InterviewLength, InterviewType
from services.groq_service import GroqService
from services.interview_service import InterviewService
from services.voice_service import VoiceService
from utils.file_utils import validate_file_path


PREDEFINED_JOB_ROLES = [
    "Java Developer",
    "Full Stack Developer",
    "Frontend Developer",
    "Backend Developer",
    "Python Developer",
    "AI/ML Engineer",
    "Data Scientist",
    "Data Analyst",
    "DevOps Engineer",
    "Custom Job Role",
]


def print_header():
    print(f"\n{CYAN}{BOLD}========================================")
    print(f"       CDA AI MOCK INTERVIEWER          ")
    print(f"========================================{RESET}\n")


def collect_configuration() -> tuple[InterviewConfig, bool, str]:
    """Collects interview setup parameters interactively from terminal."""
    print_header()

    # 0. Voice Output & Interactive Voice Preview Selection
    print(f"{BOLD}AI Interviewer Voice Output:{RESET}")
    print(" 1. 🔊  Enabled (Microsoft Edge Neural Human Voice)")
    print(" 2. 🔇  Muted (Text only)")
    voice_choice = input(f"\n{BOLD}Enter choice (1-2) [Default=1 Voice Enabled]:{RESET} ").strip()
    voice_enabled = False if voice_choice == "2" else True

    voice_persona = "guy"
    if voice_enabled:
        temp_voice_service = VoiceService()
        while True:
            print(f"\n{BOLD}Select Neural Interviewer Voice Persona:{RESET}")
            print(" 1. 👨‍💼 Guy - Senior Tech Lead (American Male)")
            print(" 2. 👨‍💼 Christopher - Executive Director (American Male)")
            print(" 3. 👩‍💼 Aria - Senior Engineering Lead (American Female)")
            print(" 4. 🇬🇧 Ryan - Tech Director (British Male)")
            persona_choice = input(f"\n{BOLD}Enter choice (1-4) [Default=1 Guy]:{RESET} ").strip()

            selected = "guy"
            sample_text = "Hello! I'm Guy, your Senior Technical Lead for today's interview session."
            if persona_choice == "2":
                selected = "christopher"
                sample_text = "Greetings! I'm Christopher, Executive Director. I look forward to our technical conversation."
            elif persona_choice == "3":
                selected = "aria"
                sample_text = "Hello there! I'm Aria, Senior Engineering Lead. I'm excited to explore your background today."
            elif persona_choice == "4":
                selected = "ryan"
                sample_text = "Hello! I'm Ryan, Tech Director. Good to meet you, let's have a great technical discussion."

            temp_voice_service.set_voice_persona(selected)
            print(f"\n{CYAN}🔊 Playing Voice Preview for {selected.title()}...{RESET}")
            temp_voice_service.speak(sample_text)

            print(f"\n{BOLD}Do you want to use this voice?{RESET}")
            print(" 1. ✅ Yes, keep this voice")
            print(" 2. 🔄 Test another voice")
            confirm = input(f"\n{BOLD}Enter choice (1-2) [Default=1 Yes]:{RESET} ").strip()
            if confirm in ["1", ""]:
                voice_persona = selected
                print(f"{GREEN}✓ Confirmed Voice Persona: {voice_persona.title()}{RESET}")
                break

    # 1. Candidate Name
    name = input(f"\n{BOLD}Candidate Name:{RESET} ").strip()
    if not name:
        name = "Candidate"

    # 2. Select Job Role
    print(f"\n{BOLD}Select Job Role:{RESET}")
    for idx, role in enumerate(PREDEFINED_JOB_ROLES, 1):
        print(f" {idx}. {role}")

    role_choice = input(f"\n{BOLD}Enter choice (1-10):{RESET} ").strip()
    job_role = "Software Engineer"
    if role_choice.isdigit():
        choice_num = int(role_choice)
        if 1 <= choice_num <= 9:
            job_role = PREDEFINED_JOB_ROLES[choice_num - 1]
        elif choice_num == 10:
            custom_role = input(f"{BOLD}Enter Custom Job Role:{RESET} ").strip()
            job_role = custom_role if custom_role else "Software Engineer"

    # 3. Seniority / Experience Level
    print(f"\n{BOLD}Select Candidate Experience Level:{RESET}")
    print(" 1. Entry-Level (0-2 years / Student / Graduate)")
    print(" 2. Mid-Level (2-5 years)")
    print(" 3. Senior (5-8 years)")
    print(" 4. Lead / Principal / Architect (8+ years)")
    level_choice = input(f"\n{BOLD}Enter choice (1-4) [Default=2 Mid-Level]:{RESET} ").strip()
    exp_level = "Mid-Level"
    if level_choice == "1":
        exp_level = "Entry-Level"
    elif level_choice == "2":
        exp_level = "Mid-Level"
    elif level_choice == "3":
        exp_level = "Senior"
    elif level_choice == "4":
        exp_level = "Lead/Architect"

    # 4. Target Career Goal (Optional)
    career_goal = input(f"\n{BOLD}Target Career Goal (e.g. 'Senior Java Engineer at Product Company') [Press Enter to Skip]:{RESET} ").strip()

    # 5. Interview Type
    print(f"\n{BOLD}Select Interview Type:{RESET}")
    types = [InterviewType.TECHNICAL, InterviewType.HR, InterviewType.BEHAVIORAL, InterviewType.RESUME_BASED, InterviewType.MIXED]
    for idx, t in enumerate(types, 1):
        print(f" {idx}. {t.value}")

    type_choice = input(f"\n{BOLD}Enter choice (1-5):{RESET} ").strip()
    selected_type = InterviewType.MIXED
    if type_choice.isdigit() and 1 <= int(type_choice) <= 5:
        selected_type = types[int(type_choice) - 1]

    # 6. Difficulty
    print(f"\n{BOLD}Select Difficulty:{RESET}")
    diffs = [DifficultyLevel.BEGINNER, DifficultyLevel.INTERMEDIATE, DifficultyLevel.ADVANCED]
    for idx, d in enumerate(diffs, 1):
        print(f" {idx}. {d.value}")

    diff_choice = input(f"\n{BOLD}Enter choice (1-3):{RESET} ").strip()
    selected_diff = DifficultyLevel.INTERMEDIATE
    if diff_choice.isdigit() and 1 <= int(diff_choice) <= 3:
        selected_diff = diffs[int(diff_choice) - 1]

    # 7. Interview Length
    print(f"\n{BOLD}Select Interview Length:{RESET}")
    print(" 1. Short (~5 questions)")
    print(" 2. Standard (~8 questions)")
    print(" 3. Detailed (~12 questions)")

    len_choice = input(f"\n{BOLD}Enter choice (1-3) or custom question count:{RESET} ").strip()
    target_count = 8
    selected_len = InterviewLength.STANDARD

    if len_choice == "1":
        target_count = 5
        selected_len = InterviewLength.SHORT
    elif len_choice == "2":
        target_count = 8
        selected_len = InterviewLength.STANDARD
    elif len_choice == "3":
        target_count = 12
        selected_len = InterviewLength.DETAILED
    elif len_choice.isdigit() and int(len_choice) > 0:
        target_count = int(len_choice)

    # 8. Resume Path (Optional)
    print(f"\n{BOLD}Resume File Path (PDF/DOCX) [Press Enter to Skip]:{RESET}")
    resume_input = input("> ").strip()
    resume_path: Optional[str] = None
    if resume_input:
        validated_p = validate_file_path(resume_input)
        if validated_p:
            resume_path = str(validated_p)
            print(f"{GREEN}✓ Resume found:{RESET} {validated_p.name}")
        else:
            print(f"{YELLOW}⚠ Resume file not found at '{resume_input}'. Proceeding without resume.{RESET}")

    config = InterviewConfig(
        candidate_name=name,
        job_role=job_role,
        experience_level=exp_level,
        target_career_goal=career_goal if career_goal else None,
        interview_type=selected_type,
        difficulty=selected_diff,
        length=selected_len,
        target_question_count=target_count,
        resume_path=resume_path,
    )
    return config, voice_enabled, voice_persona


def run_interview():
    """Main execution loop for terminal interview session with hybrid Voice & Typing support."""
    if not settings.validate():
        print(f"\n{RED}{BOLD}ERROR: GROQ_API_KEY is missing!{RESET}")
        print(f"Please copy {CYAN}.env.example{RESET} to {CYAN}.env{RESET} and set your Groq API key:\n")
        print(f"  {BOLD}GROQ_API_KEY=your_groq_api_key_here{RESET}\n")
        sys.exit(1)

    try:
        config, voice_enabled, voice_persona = collect_configuration()
        groq_service = GroqService()
        interview_service = InterviewService(groq_service=groq_service)
        voice_service = VoiceService(groq_service=groq_service, voice_persona=voice_persona)

        voice_status = f"🔊 Microsoft Edge Neural Voice ({voice_persona.title()})" if voice_enabled else "🔇 Muted"
        print(f"\n{CYAN}Initializing AI Interviewer session for {config.candidate_name}...{RESET}")
        print(f"{YELLOW}Role: {config.job_role} ({config.experience_level}){RESET}")
        print(f"{YELLOW}Audio Engine: {voice_status}{RESET}")
        print(f"{YELLOW}Analyzing role requirements & preparing strategic plan...{RESET}\n")

        # Start Session
        resp = interview_service.start_session(config)

        print(f"{GREEN}{BOLD}========================================{RESET}")
        print(f"{GREEN}{BOLD}       INTERVIEW SESSION STARTED        {RESET}")
        print(f"{GREEN}{BOLD}========================================{RESET}\n")

        # Initial Greeting (Both Text + Spoken Aloud)
        if resp.initial_greeting:
            print(f"{CYAN}{BOLD}[Interviewer Greeting]:{RESET} {resp.initial_greeting}\n")
            if voice_enabled:
                voice_service.speak(resp.initial_greeting)

        print(f"{YELLOW}Tip: Type your answer directly OR press ENTER to speak into your microphone.{RESET}")
        print(f"{YELLOW}Type 'end interview' at any prompt to finish early.{RESET}\n")

        while not resp.is_completed:
            current_q = resp.current_question
            if not current_q:
                break

            # Print Interviewer Reaction & Question
            print(f"{CYAN}{BOLD}[Interviewer]:{RESET} {resp.transition_phrase}")
            print(f"{MAGENTA}{BOLD}Question {resp.turn_number}/{resp.total_target_questions} [{current_q.question_type.value} | {current_q.difficulty.value}]:{RESET}")
            print(f"{BOLD}{current_q.text}{RESET}\n")

            # ALWAYS Speak Question Out Loud if Voice Enabled (even if user types!)
            if voice_enabled:
                voice_service.speak(f"{resp.transition_phrase}. {current_q.text}")

            # Collect Answer: Allow direct typing OR press ENTER to speak into microphone
            print(f"{CYAN}Type your answer below OR press ENTER to speak into microphone:{RESET}")
            user_input = input(f"{GREEN}{BOLD}[{config.candidate_name}]:{RESET} ").strip()

            candidate_answer = ""
            if user_input.lower() == "end interview":
                candidate_answer = "end interview"
            elif user_input:
                # User typed answer directly
                candidate_answer = user_input
            else:
                # User pressed ENTER -> record microphone audio and transcribe via Groq Whisper
                candidate_answer = voice_service.record_and_transcribe(duration_seconds=25)
                if candidate_answer:
                    print(f"\n{GREEN}{BOLD}[Transcribed Mic Audio for {config.candidate_name}]:{RESET} \"{candidate_answer}\"")

            # Handle Silence / Empty Answer gracefully
            while not candidate_answer:
                print(f"\n{YELLOW}No response detected. Please type your answer below or press ENTER to record your voice again:{RESET}")
                if voice_enabled:
                    voice_service.speak("I didn't catch that. Please type your answer or speak into your microphone.")

                re_input = input(f"{GREEN}{BOLD}[{config.candidate_name}]:{RESET} ").strip()
                if re_input.lower() == "end interview":
                    candidate_answer = "end interview"
                elif re_input:
                    candidate_answer = re_input
                else:
                    candidate_answer = voice_service.record_and_transcribe(duration_seconds=25)
                    if candidate_answer:
                        print(f"\n{GREEN}{BOLD}[Transcribed Mic Audio for {config.candidate_name}]:{RESET} \"{candidate_answer}\"")

            print(f"\n{YELLOW}Evaluating answer & deciding next action...{RESET}\n")
            resp = interview_service.process_answer(resp.session_id, candidate_answer)

        # Print Final Report & Closing Outro
        if resp.report:
            print(f"\n{GREEN}{BOLD}========================================{RESET}")
            print(f"{GREEN}{BOLD}       INTERVIEW COMPLETED              {RESET}")
            print(f"{GREEN}{BOLD}========================================{RESET}\n")

            # Closing Outro (Both Text + Spoken Aloud)
            if resp.closing_statement:
                print(f"{CYAN}{BOLD}[Interviewer Closing]:{RESET} {resp.closing_statement}\n")
                if voice_enabled:
                    voice_service.speak(resp.closing_statement)

            rep = resp.report
            print(f"{BOLD}Candidate:{RESET} {rep.candidate_name}")
            print(f"{BOLD}Role:{RESET} {rep.job_role}")
            print(f"{BOLD}Overall Score:{RESET} {CYAN}{BOLD}{rep.overall_score:.1f}/100{RESET}")
            print(f"{BOLD}Hiring Status:{RESET} {GREEN}{BOLD}{rep.hiring_readiness}{RESET}\n")

            print(f"{BOLD}Category Scores:{RESET}")
            print(f" • Technical Knowledge: {rep.technical_score:.1f}/100")
            print(f" • Communication:       {rep.communication_score:.1f}/100")
            print(f" • Problem Solving:     {rep.problem_solving_score:.1f}/100")
            print(f" • Resume Knowledge:    {rep.resume_knowledge_score:.1f}/100")
            print(f" • Answer Clarity:      {rep.clarity_score:.1f}/100")
            print(f" • Role Readiness:      {rep.role_readiness_score:.1f}/100")

            print(f"\n{BOLD}Executive Summary:{RESET}\n{rep.summary}\n")

            if resp.report_txt_path:
                print(f"{GREEN}✓ Full Text Report Saved:{RESET} {resp.report_txt_path}")
            if resp.report_json_path:
                print(f"{GREEN}✓ JSON Data Report Saved:{RESET} {resp.report_json_path}")
            print(f"\n{CYAN}Thank you for completing the CDA AI Mock Interview!{RESET}\n")

    except KeyboardInterrupt:
        print(f"\n\n{YELLOW}Interview session terminated by user.{RESET}")
        sys.exit(0)
    except Exception as e:
        print(f"\n{RED}{BOLD}An error occurred during the interview session:{RESET} {e}")
        sys.exit(1)


if __name__ == "__main__":
    run_interview()
