#!/usr/bin/env python3
"""
Process Gmail-imported audio files according to email notes.
Analyzes audio to find best segments, trims, loops, and saves
with proper names for the Hunting Call app.
"""

import os
import sys
import wave
import struct
import subprocess
import shutil
from pathlib import Path

GMAIL_DIR = Path("assets/audio/gmail_imports")
OUTPUT_DIR = Path("assets/audio")


def get_duration(wav_path):
    """Get WAV file duration in seconds."""
    with wave.open(str(wav_path), 'rb') as w:
        return w.getnframes() / w.getframerate()


def analyze_rms(wav_path, start_sec, end_sec, window_sec):
    """
    Analyze a WAV file and find the window with the highest RMS amplitude.
    Returns (best_start, best_end) in seconds.
    """
    with wave.open(str(wav_path), 'rb') as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        sw = w.getsampwidth()
        
        start_frame = int(start_sec * sr)
        end_frame = int(end_sec * sr)
        window_frames = int(window_sec * sr)
        
        w.setpos(start_frame)
        total_frames = end_frame - start_frame
        raw = w.readframes(total_frames)
    
    # Parse samples
    if sw == 2:
        fmt = f"<{total_frames * ch}h"
        samples = list(struct.unpack(fmt, raw))
    else:
        print(f"  Warning: {sw}-byte samples, using raw analysis")
        samples = list(raw)
    
    # If stereo, average channels
    if ch == 2:
        samples = [(samples[i] + samples[i+1]) / 2 for i in range(0, len(samples), 2)]
    
    sr_actual = len(samples) / (end_sec - start_sec)
    window_samples = int(window_sec * sr_actual)
    
    best_rms = 0
    best_pos = 0
    
    step = int(sr_actual * 0.1)  # slide by 100ms
    if step < 1:
        step = 1
    
    for i in range(0, len(samples) - window_samples, step):
        chunk = samples[i:i + window_samples]
        rms = (sum(s * s for s in chunk) / len(chunk)) ** 0.5
        if rms > best_rms:
            best_rms = rms
            best_pos = i
    
    best_start = start_sec + (best_pos / sr_actual)
    best_end = best_start + window_sec
    
    return round(best_start, 2), round(best_end, 2)


def ffmpeg_trim(src, dst, start, end):
    """Trim a WAV file from start to end seconds."""
    duration = end - start
    cmd = [
        "ffmpeg", "-y", "-i", str(src),
        "-ss", str(start), "-t", str(duration),
        "-acodec", "pcm_s16le", "-ar", "44100",
        str(dst)
    ]
    subprocess.run(cmd, capture_output=True)


def ffmpeg_trim_silence(src, dst, target_duration=10):
    """Trim a WAV file to target duration, removing silence."""
    # First pass: detect non-silent segments
    cmd = [
        "ffmpeg", "-y", "-i", str(src),
        "-af", "silenceremove=start_periods=1:start_silence=0.3:start_threshold=-40dB:stop_periods=-1:stop_silence=0.3:stop_threshold=-40dB",
        "-acodec", "pcm_s16le", "-ar", "44100",
        str(dst)
    ]
    subprocess.run(cmd, capture_output=True)
    
    # Check duration and trim if too long
    dur = get_duration(dst)
    if dur > target_duration:
        temp = dst.with_suffix('.tmp.wav')
        shutil.move(str(dst), str(temp))
        ffmpeg_trim(temp, dst, 0, target_duration)
        temp.unlink()


def ffmpeg_loop(src, dst, segment_end, times):
    """Loop a segment of a WAV file N times."""
    # First extract the segment - use absolute paths
    temp = dst.parent / (dst.stem + '_segment.wav')
    ffmpeg_trim(src, temp, 0, segment_end)
    
    # Create concat file with absolute paths
    concat_file = dst.parent / (dst.stem + '_concat.txt')
    abs_temp = str(temp.resolve()).replace('\\', '/')
    with open(concat_file, 'w') as f:
        for _ in range(times):
            f.write(f"file '{abs_temp}'\n")
    
    cmd = [
        "ffmpeg", "-y", "-f", "concat", "-safe", "0",
        "-i", str(concat_file),
        "-acodec", "pcm_s16le", "-ar", "44100",
        str(dst)
    ]
    subprocess.run(cmd, capture_output=True)
    
    # Cleanup
    temp.unlink(missing_ok=True)
    concat_file.unlink(missing_ok=True)


def process_file(src_name, dst_name, action, **kwargs):
    """Process a single file according to its action."""
    src = GMAIL_DIR / src_name
    dst = OUTPUT_DIR / dst_name
    
    if not src.exists():
        print(f"  ERROR: {src} not found!")
        return False
    
    dur = get_duration(src)
    print(f"\n{'='*50}")
    print(f"  Source:   {src_name} ({dur:.1f}s)")
    print(f"  Target:   {dst_name}")
    print(f"  Action:   {action}")
    
    if action == "copy":
        shutil.copy2(str(src), str(dst))
        print(f"  Result:   Copied as-is")
        
    elif action == "trim":
        start = kwargs.get("start", 0)
        end = kwargs.get("end", dur)
        ffmpeg_trim(src, dst, start, end)
        new_dur = get_duration(dst)
        print(f"  Result:   Trimmed {start}s-{end}s -> {new_dur:.1f}s")
        
    elif action == "trim_silence":
        target = kwargs.get("target_duration", 10)
        ffmpeg_trim_silence(src, dst, target)
        new_dur = get_duration(dst)
        print(f"  Result:   Silence removed, trimmed to {new_dur:.1f}s")
        
    elif action == "best_segment":
        search_start = kwargs.get("search_start", 0)
        search_end = kwargs.get("search_end", dur)
        segment_len = kwargs.get("segment_len", 6)
        
        # Clamp search_end to actual duration
        if search_end > dur:
            search_end = dur
        
        if search_end - search_start < segment_len:
            # Segment longer than search range, just trim to range
            ffmpeg_trim(src, dst, search_start, search_end)
            new_dur = get_duration(dst)
            print(f"  Result:   Range too short for {segment_len}s, used {search_start}s-{search_end}s -> {new_dur:.1f}s")
        else:
            best_start, best_end = analyze_rms(src, search_start, search_end, segment_len)
            print(f"  Analysis: Best {segment_len}s segment at {best_start}s-{best_end}s")
            ffmpeg_trim(src, dst, best_start, best_end)
            new_dur = get_duration(dst)
            print(f"  Result:   Extracted {new_dur:.1f}s")
        
    elif action == "loop":
        segment_end = kwargs.get("segment_end", 2)
        times = kwargs.get("times", 3)
        ffmpeg_loop(src, dst, segment_end, times)
        new_dur = get_duration(dst)
        print(f"  Result:   First {segment_end}s looped {times}x -> {new_dur:.1f}s")
    
    return True


def main():
    print("=" * 50)
    print("Gmail Audio Processing Script")
    print("=" * 50)
    
    results = []
    
    # --- DIRECT REPLACEMENTS ---
    print("\n### DIRECT REPLACEMENTS ###")
    
    # 1. Buck Grunt - best quality, use as-is
    results.append(process_file(
        "016-Buck_Grunt.wav", "deer_buck_grunt.wav",
        "copy"
    ))
    
    # 2. Buck Snort Wheeze - first 30s
    results.append(process_file(
        "023-Buck_Snort_Wheeze.wav", "deer_snort_wheeze.wav",
        "trim", start=0, end=30
    ))
    
    # 3. Doe Bleat - trim to ~10s, remove silence
    results.append(process_file(
        "132-Doe_Bleat.wav", "deer_doe_bleat.wav",
        "trim_silence", target_duration=10
    ))
    
    # --- NEW SOUNDS ---
    print("\n### NEW SOUNDS ###")
    
    # 4. Black Bear Cub Distress - best 6s between 8-18s
    results.append(process_file(
        "012-Black_Bear_Cub_Distress.wav", "black_bear_cub_distress.wav",
        "best_segment", search_start=8, search_end=18, segment_len=6
    ))
    
    # 5. Buck Dominant Grunt - first 30s
    results.append(process_file(
        "015-Buck_Dominant_Grunt.wav", "deer_dominant_grunt.wav",
        "trim", start=0, end=30
    ))
    
    # 6. Buck Social Grunt - first 20s
    results.append(process_file(
        "025-Buck_Social_Grunt_ORION.wav", "deer_social_grunt.wav",
        "trim", start=0, end=20
    ))
    
    # 7. Buck Tending Grunt - new sound, use as-is
    results.append(process_file(
        "026-Buck_Tending_Grunt.wav", "deer_tending_grunt.wav",
        "copy"
    ))
    
    # 8. Buck Challenge - loop first 2s, 3 times
    results.append(process_file(
        "BuckChallenge_by_Dave_Kelso.wav", "deer_buck_challenge.wav",
        "loop", segment_end=2, times=3
    ))
    
    # 9. Buck Tending Grunt v2 - best 6s of full 12s
    results.append(process_file(
        "BuckTendingGrunt_By_Dave_Kelso.wav", "deer_tending_grunt_v2.wav",
        "best_segment", search_start=0, search_end=12, segment_len=6
    ))
    
    # 10. Doe Estrus Bleat - great sound, use as-is
    results.append(process_file(
        "140-Doe_Estrus_Bleat_Mild.wav", "deer_estrus_bleat.wav",
        "copy"
    ))
    
    # 11. Fawn Distress - keep as-is (compare with 168 later)
    results.append(process_file(
        "163-Fawn_Distress.wav", "deer_fawn_distress.wav",
        "copy"
    ))
    
    # 12. Fawn Deer Distress v2 - first 20s, best 10s
    results.append(process_file(
        "168-Fawn_Deer_Distress.wav", "deer_fawn_distress_v2.wav",
        "best_segment", search_start=0, search_end=20, segment_len=10
    ))
    
    # 13. Lost Fawn - best 5s of 10s
    results.append(process_file(
        "LostFawn_by_Dave_Kelso.wav", "deer_lost_fawn.wav",
        "best_segment", search_start=0, search_end=10, segment_len=5
    ))
    
    # --- SUMMARY ---
    success = sum(1 for r in results if r)
    print(f"\n{'='*50}")
    print(f"Processing complete!")
    print(f"  Processed: {success}/{len(results)} files")
    print(f"  Skipped:   Funny-tagged sounds (for later)")
    print(f"{'='*50}")
    
    # Show skipped funny sounds
    print(f"\nSkipped (funny tag, for later):")
    print(f"  - 020-Buck_Rubbing_Tree.wav")
    print(f"  - 030-Bucks_Sparring.wav")
    print(f"  - 131-Deer_Pawing.wav")
    print(f"  - DoeInHeat_by_Dave_Kelso.wav")


if __name__ == "__main__":
    main()
