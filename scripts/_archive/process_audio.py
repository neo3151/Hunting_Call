import os
import json
import shutil
import subprocess
import sys

# Configuration
INPUT_DIR = "downloaded_audio"
OUTPUT_DIR = "assets/audio"
MAPPING_FILE = "assets/data/reference_calls.json"
FFMPEG_CMD = "ffmpeg" # Ensure ffmpeg is in your PATH

def check_ffmpeg():
    """Check if ffmpeg is installed."""
    try:
        subprocess.run([FFMPEG_CMD, "-version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except FileNotFoundError:
        print("Error: ffmpeg not found. Please install ffmpeg and add it to your PATH.")
        return False

def load_mapping():
    """Load the call ID to filename mapping from reference_calls.json."""
    try:
        with open(MAPPING_FILE, 'r') as f:
            data = json.load(f)
            mapping = {}
            for call in data['calls']:
                # Map animal name + call type to the expected filename
                key = f"{call['animalName']} - {call['callType']}".lower()
                # Extract filename from path
                filename = os.path.basename(call['audioAssetPath'])
                mapping[key] = filename
            return mapping
    except FileNotFoundError:
        print(f"Error: Could not find {MAPPING_FILE}")
        return {}

def process_audio():
    """Process audio files in the input directory."""
    if not check_ffmpeg():
        return

    if not os.path.exists(INPUT_DIR):
        os.makedirs(INPUT_DIR)
        print(f"Created input directory: {INPUT_DIR}")
        print("Please place your downloaded audio files here and rename them to match 'Animal Name - Call Type' (e.g., 'Elk - Cow Mew.mp3')")
        return

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    mapping = load_mapping()
    if not mapping:
        return

    print("Processing audio files...")
    
    for filename in os.listdir(INPUT_DIR):
        name, ext = os.path.splitext(filename)
        # normalize name for matching
        normalized_name = name.lower().replace("_", " ").strip()
        
        # Try to find a match in our mapping
        target_filename = mapping.get(normalized_name)
        
        if not target_filename:
            # Try fuzzy matching or just checking if the file matches a target ID?
            # For now, let's rely on the user naming the input files roughly correctly
            # Or we can iterate through values
             if filename in mapping.values():
                 target_filename = filename
        
        if target_filename:
            input_path = os.path.join(INPUT_DIR, filename)
            output_path = os.path.join(OUTPUT_DIR, target_filename)
            
            print(f"Converting {filename} -> {target_filename}")
            
            # FFmpeg command: Convert to 16-bit PCM WAV at 44.1kHz
            try:
                subprocess.run([
                    FFMPEG_CMD,
                    "-y", # Overwrite output
                    "-i", input_path,
                    "-acodec", "pcm_s16le",
                    "-ar", "44100",
                    "-ac", "1", # Mono is usually fine for calls, stereo if preferred
                    output_path
                ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"Success: {target_filename}")
            except subprocess.CalledProcessError:
                print(f"Error converting {filename}")
        else:
            print(f"Skipping {filename}: Could not find matching call in database. Rename file to 'Animal Name - Call Type' or the target filename.")

if __name__ == "__main__":
    process_audio()
