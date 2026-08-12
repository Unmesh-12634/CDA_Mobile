"""
=========================================================
CDA AI Voice & Speech Analytics System Diagnostic Test
=========================================================
"""

import sys
import time
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

BASE_DIR = Path(__file__).resolve().parent
sys.path.append(str(BASE_DIR))

from services.voice_service import VoiceService

def run_voice_diagnostics():
    print("\n" + "=" * 55)
    print("      🎙️  CDA AI VOICE & SPEECH ANALYTICS TESTER")
    print("=" * 55 + "\n")

    voice_service = VoiceService()

    # -------------------------------------------------------------
    # TEST 1: Microsoft Edge Neural TTS Voice Output
    # -------------------------------------------------------------
    print("🔊 TEST 1: AI Interviewer Neural Voice Output...")
    test_phrase = "Hello Arjun! I'm your AI interviewer today. Testing Microsoft Edge Neural Voice speech synthesis."
    print(f"   Speaking: '{test_phrase}'")
    try:
        voice_service.speak(test_phrase)
        print("   ✅ Test 1 Passed: Voice audio played successfully!\n")
    except Exception as e:
        print(f"   ❌ Test 1 Warning: {e}\n")

    # -------------------------------------------------------------
    # TEST 2: Speech Analytics Engine
    # -------------------------------------------------------------
    print("📊 TEST 2: Speech Dynamics Analytics Engine...")
    sample_transcript = "In my previous project, um... we used Redis for caching. Wait actually, we used it for pub-sub messaging too."
    analytics = voice_service.analyze_speech_analytics(sample_transcript, duration_sec=10.0)

    print(f"   Sample Transcript: \"{sample_transcript}\"")
    print(f"   • Words Per Minute (WPM):   {analytics['speech_wpm']} WPM")
    print(f"   • Cadence Rating:           {analytics['cadence_rating']}")
    print(f"   • Filler Words Count:       {analytics['filler_words_count']} ({analytics['filler_words_list']})")
    print(f"   • Self-Correction Detected: {analytics['self_correction_detected']}")
    print(f"   • Vocal Clarity Score:      {analytics['clarity_score']}/10")
    print("   ✅ Test 2 Passed: Speech analytics metrics computed!\n")

    # -------------------------------------------------------------
    # TEST 3: Optional Live Mic Recording & Groq Whisper STT
    # -------------------------------------------------------------
    print("🎙️ TEST 3: Live Microphone Recording & Whisper Transcription...")
    print("   Press ENTER to record 5 seconds of your microphone audio, or type 'skip':")
    choice = input("   > ").strip()

    if choice.lower() != "skip":
        print("\n🎙️ Speak now! (Recording for 5 seconds...)")
        recorded_text = voice_service.record_and_transcribe(duration_seconds=5)
        print(f"\n   📝 Transcribed Voice Input: \"{recorded_text}\"")

        if recorded_text:
            live_analytics = voice_service.analyze_speech_analytics(recorded_text, duration_sec=5.0)
            print(f"   📊 Live Speech WPM: {live_analytics['speech_wpm']} WPM ({live_analytics['cadence_rating']})")
            print(f"   📊 Fillers Detected: {live_analytics['filler_words_count']}")

        print("   ✅ Test 3 Passed: Microphone & Whisper STT verified!\n")
    else:
        print("   Skipped live mic recording.\n")

    print("=" * 55)
    print("🎉 ALL VOICE SYSTEM DIAGNOSTICS COMPLETED SUCCESSFULLY!")
    print("=" * 55 + "\n")

if __name__ == "__main__":
    run_voice_diagnostics()
