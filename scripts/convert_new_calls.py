"""
Convert new hunting call WAVs to normalized MP3 and copy to assets/audio/.
"""
import subprocess
import os
import sys

SOURCE_DIRS = [
    r"C:\Users\neo31\Downloads\_extracted_good_for_app",
    r"C:\Users\neo31\Downloads\_extracted_in_app_calls_2",
]
OUTPUT_DIR = r"C:\Users\neo31\Hunting_Call\assets\audio"

# Mapping: source filename -> target mp3 filename
FILE_MAP = {
    # === Good for app ===
    # Mallard Duck (existing species)
    "Mallard_best_flight_call_clean.wav": "mallard_flight_call.mp3",
    "Mallard_call_flying_trimmed_clean.wav": "mallard_flying_call.mp3",
    "Mallard_call_quick_repeated_clean.wav": "mallard_quick_quack.mp3",
    "Mallard_long_quack_part1_0-8s_clean.wav": "mallard_long_quack_1.mp3",
    "Mallard_long_quack_part2_20-28s_clean.wav": "mallard_long_quack_2.mp3",
    "Mallard_quack_with_chirp_trimmed_clean.wav": "mallard_quack_chirp.mp3",
    # Green-Winged Teal (existing species, listed as "Blue-Winged Teal" category-wise — but these are Green-Winged)
    "Green_winged_teal_alarm_call_edited.wav": "green_winged_teal_alarm.mp3",
    "Green_winged_teal_call_fly_edited.wav": "green_winged_teal_flight.mp3",
    "Green_winged_teal_call_repeated_edited.wav": "green_winged_teal_repeated.mp3",
    "Green_winged_teal_whistles_composite_edited.wav": "green_winged_teal_whistle.mp3",
    # American Wigeon (NEW species)
    "American_Wigeon_female_call_edited.wav": "american_wigeon_female_call.mp3",
    "American_Wigeon_song_composite_edited.wav": "american_wigeon_song.mp3",
    # Bufflehead (NEW species)
    "Bufflehead_female_flush_out_looped_edited.wav": "bufflehead_flush_out.mp3",
    "Bufflehead_long_recording_6-7s_repeated_edited.wav": "bufflehead_long_call.mp3",
    "Bufflehead_quick_alarm_call_repeated_edited.wav": "bufflehead_alarm.mp3",
    # Gadwall (NEW species)
    "Gadwall_alarm_call_edited.wav": "gadwall_alarm.mp3",
    "Gadwall_alarm_call_2_edited.wav": "gadwall_alarm_2.mp3",
    "Gadwall_flight_call_segment_edited.wav": "gadwall_flight.mp3",
    # Northern Shoveler (NEW species)
    "Northern_Shoveler_alarm_call_edited.wav": "northern_shoveler_alarm.mp3",
    "Northern_Shoveler_chirp_8-12s_edited.wav": "northern_shoveler_chirp.mp3",
    "Northern_Shoveler_quick_call_repeated_edited.wav": "northern_shoveler_quick.mp3",
    # Wild Turkey (existing species)
    "Turkey_single_bird_roost_edited.wav": "turkey_roost.mp3",
    "Turkey_unique_call_edited.wav": "turkey_unique.mp3",

    # === In app calls 2 ===
    # Blue-Winged Teal (existing species)
    "XC163734_bw_teal_cluck_edited.wav": "bw_teal_cluck.mp3",
    "XC173322_bw_teal_flying_call_repeated.wav": "bw_teal_flying.mp3",
    "XC363099_bw_teal_song_edited.wav": "bw_teal_song.mp3",
    # Wood Duck (existing species)
    "XC331424_wood_duck_flushed_out_edited.wav": "wood_duck_flushed.mp3",
    "XC356416_wood_duck_flying_call_edited.wav": "wood_duck_flying.mp3",
    "XC356971_wood_duck_scared_edited.wav": "wood_duck_scared.mp3",
    "XC754267_wood_duck_squeal_edited.wav": "wood_duck_squeal.mp3",
    # Muscovy Duck (NEW species)
    "XC931256_muscovy_quack_repeated.wav": "muscovy_quack.mp3",
    # Fulvous Whistling-Duck (NEW species)
    "XC277978_fulvous_cricket_cleaned.wav": "fulvous_whistling_duck.mp3",
    # American Crow (existing species)
    "crow_alarm_clean.wav": "crow_alarm.mp3",
    "crow_caw_looped_edited.wav": "crow_caw_looped.mp3",
    # Lion (NEW species)
    "lion_scream_clean.wav": "lion_scream.mp3",
}

def find_source(filename):
    for d in SOURCE_DIRS:
        path = os.path.join(d, filename)
        if os.path.exists(path):
            return path
    return None

def convert(src, dst):
    cmd = [
        "ffmpeg", "-y", "-i", src,
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ar", "44100", "-ac", "1",
        "-b:a", "192k",
        dst
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  ERROR: {result.stderr[-200:]}")
        return False
    return True

if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    success = 0
    fail = 0
    for src_name, dst_name in sorted(FILE_MAP.items()):
        src_path = find_source(src_name)
        if not src_path:
            print(f"SKIP (not found): {src_name}")
            fail += 1
            continue
        dst_path = os.path.join(OUTPUT_DIR, dst_name)
        if os.path.exists(dst_path):
            print(f"EXISTS: {dst_name}")
            success += 1
            continue
        print(f"Converting: {src_name} -> {dst_name} ... ", end="", flush=True)
        if convert(src_path, dst_path):
            size_kb = os.path.getsize(dst_path) / 1024
            print(f"OK ({size_kb:.0f} KB)")
            success += 1
        else:
            fail += 1
    
    print(f"\nDone: {success} converted, {fail} failed")
