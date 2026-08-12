"""
=========================================================
CDA AI Microphone & Fast Speech Recognition Test
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

def run_fast_mic_test():
    print("\n" + "=" * 60)
    print("      🎙️  CDA LIVE MICROPHONE & FAST WHISPER STT TESTER")
    print("=" * 60 + "\n")

    voice_service = VoiceService()

    print("🔴 RECORDING STARTED! Speak into your microphone now...")
    print("   (Recording for 5 seconds. Say something like: 'Hello I am Arjun testing voice input')\n")
    
    start_time = time.time()
    wav_path = voice_service.record_microphone_audio(duration_seconds=5)
    record_duration = round(time.time() - start_time, 2)

    if not wav_path or not wav_path.exists():
        print("❌ Error: Could not access microphone or save audio file.")
        print("   Make sure microphone permissions are granted.")
        return

    print(f"\n⚡ Transcribing audio via Groq Whisper Large v3 (Fast Cloud Inference)...")
    stt_start = time.time()
    transcript = voice_service.groq_service.transcribe_audio(wav_path)
    stt_duration = round(time.time() - stt_start, 2)

    print("\n" + "─" * 60)
    print(f"📝 Transcribed Text : \"{transcript}\"")
    print(f"⚡ STT Latency      : {stt_duration} seconds (Ultra-Fast!)")
    print("─" * 60)

    if transcript:
        analytics = voice_service.analyze_speech_analytics(transcript, duration_sec=5.0)
        print(f"\n📊 SPEECH ANALYTICS BREAKDOWN:")
        print(f"   • Speech Cadence (WPM)  : {analytics['speech_wpm']} WPM ({analytics['cadence_rating']})")
        print(f"   • Filler Words Count    : {analytics['filler_words_count']} ({analytics['filler_words_list']})")
        print(f"   • Self-Correction Flag  : {analytics['self_correction_detected']}")
        print(f"   • Vocal Clarity Score   : {analytics['clarity_score']}/10")
        print("\n✅ SUCCESS: Microphone voice input & transcription working smooth & clear!")
    else:
        print("\n⚠️ No speech detected. Please check if your microphone is unmuted and try again.")

    print("\n" + "=" * 60 + "\n")

if __name__ == "__main__":
    run_fast_mic_test()
