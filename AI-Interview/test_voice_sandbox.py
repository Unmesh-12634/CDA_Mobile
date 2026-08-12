"""
=========================================================
CDA Interactive AI Voice Input Sandbox & Real-time Visualizer
=========================================================
"""

import sys
import time
import math
import numpy as np
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

BASE_DIR = Path(__file__).resolve().parent
sys.path.append(str(BASE_DIR))

try:
    import sounddevice as sd
    import scipy.io.wavfile as wav
    HAS_AUDIO = True
except ImportError:
    HAS_AUDIO = False

from services.voice_service import VoiceService
from utils.logger import get_logger

logger = get_logger("voice_sandbox")

def generate_volume_bar(volume_norm: float, width: int = 15) -> str:
    """Generates a dynamic visual audio equalizer waveform based on microphone volume amplitude."""
    blocks = [" ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    scaled = int(volume_norm * width)
    scaled = max(0, min(width, scaled))
    
    # Create animated equalizer visualization
    bar = ""
    for i in range(width):
        if i < scaled:
            idx = min(len(blocks) - 1, int((i / max(1, scaled)) * len(blocks)))
            bar += blocks[idx]
        else:
            bar += " "
    return f"[{bar}]"

def record_audio_with_waveform(duration_seconds: float = 8.0, sample_rate: int = 16000) -> tuple:
    """Records microphone audio with real-time live visual waveform animation."""
    if not HAS_AUDIO:
        print("❌ Error: sounddevice or scipy not installed.")
        return None, 0.0

    temp_dir = BASE_DIR / "data" / "temp"
    temp_dir.mkdir(parents=True, exist_ok=True)
    temp_wav_path = temp_dir / "sandbox_recording.wav"

    print("\n" + "═" * 60)
    print(" 🎙️  RECORDING LIVE NOW! Speak into your microphone...")
    print(" 💡 Press ENTER at any time to finish speaking immediately.")
    print("═" * 60 + "\n")

    frames = []
    start_time = time.time()
    block_size = int(sample_rate * 0.1) # 100ms chunks

    def callback(indata, frame_count, time_info, status):
        frames.append(indata.copy())

    with sd.InputStream(samplerate=sample_rate, channels=1, dtype="int16", callback=callback):
        while time.time() - start_time < duration_seconds:
            elapsed = time.time() - start_time
            remaining = max(0.0, duration_seconds - elapsed)

            # Compute current volume amplitude RMS if frames available
            if frames:
                recent_data = frames[-1]
                rms = np.sqrt(np.mean(recent_data.astype(np.float32) ** 2))
                norm_volume = min(1.0, rms / 4000.0) # Normalize
            else:
                norm_volume = 0.0

            vol_bar = generate_volume_bar(norm_volume, width=20)
            
            # Print live updating status line
            sys.stdout.write(f"\r 🔴 RECORDING {vol_bar}  Time: {elapsed:.1f}s / {duration_seconds:.1f}s  (Press ENTER to stop)")
            sys.stdout.flush()

            # Check if user pressed ENTER to stop recording early
            if select_file_descriptors():
                sys.stdin.readline()
                break

            time.sleep(0.08)

    actual_duration = round(time.time() - start_time, 2)
    print(f"\n\n🛑 Recording finished ({actual_duration}s captured). Saving audio...")

    if not frames:
        return None, 0.0

    audio_data = np.concatenate(frames, axis=0)
    wav.write(str(temp_wav_path), sample_rate, audio_data)
    return temp_wav_path, actual_duration

def select_file_descriptors():
    """Cross-platform non-blocking stdin check."""
    try:
        import msvcrt
        return [sys.stdin] if msvcrt.kbhit() else []
    except ImportError:
        import select
        return select.select([sys.stdin], [], [], 0)[0]

def main():
    voice_service = VoiceService()

    while True:
        print("\n" + "═" * 65)
        print("         👑 CDA INTERACTIVE VOICE INPUT & WAVEFORM TESTER")
        print("═" * 65)
        print(" 1. Press SPACEBAR + ENTER to Start Voice Recording")
        print(" 2. Type 'exit' to quit")
        print("═" * 65)

        cmd = input("\n👉 Select option: ").strip()
        if cmd.lower() in ["exit", "q", "quit"]:
            print("Exiting Voice Sandbox. Goodbye!")
            break

        # Record with Live Equalizer Waveform
        wav_path, duration = record_audio_with_waveform(duration_seconds=10.0)
        if not wav_path or not wav_path.exists():
            print("❌ Recording failed.")
            continue

        # Fast Cloud STT Transcription
        print("⚡ Transcribing your voice via Groq Whisper AI...")
        stt_start = time.time()
        transcript = voice_service.groq_service.transcribe_audio(wav_path)
        stt_time = round(time.time() - stt_start, 2)

        print("\n" + "┌" + "─" * 63 + "┐")
        print(f"│ 📝 YOUR TRANSCRIBED VOICE TEXT:                             │")
        print(f"│ \"{transcript}\"")
        print(f"│ ⚡ STT Latency: {stt_time} seconds                                 │")
        print("└" + "─" * 63 + "┘")

        if transcript:
            # Analyze Speech Dynamics
            analytics = voice_service.analyze_speech_analytics(transcript, duration_sec=duration)
            print(f"\n📊 SPEECH DYNAMICS BREAKDOWN:")
            print(f"   • Speaking Tempo (WPM)  : {analytics['speech_wpm']} WPM ({analytics['cadence_rating']})")
            print(f"   • Filler Words Detected : {analytics['filler_words_count']} ({analytics['filler_words_list']})")
            print(f"   • Self-Correction Flag  : {analytics['self_correction_detected']}")
            print(f"   • Vocal Clarity Score   : {analytics['clarity_score']}/10")

            # Speak back confirmation using Edge Neural TTS
            ai_reply = f"I heard you loud and clear! You said: {transcript[:80]}"
            print(f"\n🔊 AI Interviewer Response: '{ai_reply}'")
            voice_service.speak(ai_reply)

if __name__ == "__main__":
    main()
