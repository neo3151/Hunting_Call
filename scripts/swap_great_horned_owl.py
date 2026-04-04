import os
import subprocess

def main():
    print("🦉 Great Horned Owl Replacement Utility")
    print("─" * 40)
    
    gho_path = "assets/audio/gho.mp3"
    gho_raw_path = "assets/audio/gho_raw.mp3"
    
    print("🧹 Step 1: Removing old asset...")
    if os.path.exists(gho_path):
        os.remove(gho_path)
        print("  - Deleted existing gho.mp3")
    else:
        print("  - No existing gho.mp3 found.")

    url = "https://youtube.com/shorts/x_-Z6j88LPk"
    print(f"\n📥 Step 2: Downloading audio clip from YouTube Shorts...")
    dl_cmd = [
        "yt-dlp",
        "-x", "--audio-format", "mp3",
        "--audio-quality", "0",
        "-o", gho_raw_path,
        url
    ]
    try:
        subprocess.run(dl_cmd, check=True)
    except Exception as e:
        print(f"❌ Failed to download audio. Please install yt-dlp if it's missing. Error: {e}")
        return

    print("\n✨ Step 3: Conducting basic audio clean-up...")
    print("  - Trimming leading silence")
    print("  - Reducing background noise (afftdn)")
    print("  - Normalizing overall volume (loudnorm)")
    
    ffmpeg_cmd = [
        "ffmpeg", "-y", "-i", gho_raw_path,
        "-af", "silenceremove=start_periods=1:start_duration=0.1:start_threshold=-40dB,afftdn=nf=-20,loudnorm",
        gho_path
    ]
    try:
        subprocess.run(ffmpeg_cmd, check=True)
    except Exception as e:
        print(f"❌ ffmpeg failed. Make sure ffmpeg is in your PATH. Error: {e}")
        return

    # Clean intermediate
    if os.path.exists(gho_raw_path):
        os.remove(gho_raw_path)
    
    print("\n📈 Step 4: Regenerating JSON references (Waveform / Spectrogram)...")
    if os.path.exists("scripts/reprocess_waveforms.py"):
        subprocess.run(["python", "scripts/reprocess_waveforms.py"])
    else:
        print("  - ⚠️ scripts/reprocess_waveforms.py not found.")

    if os.path.exists("scripts/extract_spectrograms.py"):
        subprocess.run(["python", "scripts/extract_spectrograms.py"])
    else:
        print("  - ⚠️ scripts/extract_spectrograms.py not found.")
    
    print("\n✅ Great Horned Owl completely updated and synced into the app data!")

if __name__ == '__main__':
    main()
