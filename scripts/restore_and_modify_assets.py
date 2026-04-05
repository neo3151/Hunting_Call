import json
import os
import subprocess
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_FILE = os.path.join(BASE, 'assets', 'data', 'reference_calls.json')
TEST_REF = os.path.join(BASE, 'assets', 'data', 'reference_calls_test.json')

def main():
    print("1. Restoring Cougar ('cougar_scream_v2') to Database...")
    
    with open(REF_FILE, 'r', encoding='utf-8') as f:
        main_data = json.load(f)
        
    with open(TEST_REF, 'r', encoding='utf-8') as f:
        test_data = json.load(f)
        
    main_calls = main_data.get('calls', [])
    
    cougar_index = next((i for i, c in enumerate(main_calls) if c['id'] == 'cougar_scream_v2'), -1)
    if cougar_index != -1:
        print("  [✓] 'cougar_scream_v2' already exists in reference_calls.json.")
    else:
        cougar_call = next((c for c in test_data.get('calls', []) if c['id'] == 'cougar_scream_v2'), None)
        if cougar_call:
            # Let's insert it right after the normal cougar call, or at the end
            base_cougar_idx = next((i for i, c in enumerate(main_calls) if c['id'] == 'cougar'), -1)
            if base_cougar_idx != -1:
                main_calls.insert(base_cougar_idx + 1, cougar_call)
            else:
                main_calls.append(cougar_call)
                
            with open(REF_FILE, 'w', encoding='utf-8') as f:
                json.dump(main_data, f, indent=2, ensure_ascii=False)
            with open(REF_FILE, 'a', encoding='utf-8') as f:
                f.write('\n')
            print("  [+] Added 'cougar_scream_v2' back to reference_calls.json successfully!")
        else:
            print("  [-] Could not find 'cougar_scream_v2' in the test database.")
            
    print("\n2. Restoring cougar_scream.mp3 from git history...")
    audio_path = os.path.join(BASE, "assets", "audio", "cougar_scream.mp3")
    if not os.path.exists(audio_path):
        try:
            # Find the commit before it was deleted
            cmd = 'git rev-list -n 1 HEAD -- assets/audio/cougar_scream.mp3'
            commit = subprocess.check_output(cmd, shell=True, text=True, cwd=BASE).strip()
            
            if commit:
                # Checkout the file exactly before the moment it was deleted
                print(f"  [i] Found history at commit: {commit}. Extracting...")
                checkout_cmd = f"git checkout {commit}^ -- assets/audio/cougar_scream.mp3"
                subprocess.run(checkout_cmd, shell=True, cwd=BASE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                # If the file didn't exist directly before, try just checking out the exact commit
                if not os.path.exists(audio_path):
                    checkout_cmd2 = f"git checkout {commit} -- assets/audio/cougar_scream.mp3"
                    subprocess.run(checkout_cmd2, shell=True, cwd=BASE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    
                if os.path.exists(audio_path):
                    print("  [+] Successfully restored cougar_scream.mp3 from git!")
                else:
                    print("  [-] Failed to checkout cougar_scream.mp3 from git history.")
            else:
                print("  [-] Could not find git history for cougar_scream.mp3.")
        except Exception as e:
            print("  [-] Error checking out from git:", e)
    else:
        print("  [✓] cougar_scream.mp3 already exists on disk.")

    print("\n3. Doubling Great Horned Owl (gho.mp3) audio...")
    gho_path = os.path.join(BASE, "assets", "audio", "gho.mp3")
    if not os.path.exists(gho_path):
        print("  [-] gho.mp3 not found!")
        return

    try:
        from pydub import AudioSegment
        print("  [i] Using pydub to duplicate audio layer...")
        sound = AudioSegment.from_mp3(gho_path)
        doubled = sound + sound
        doubled.export(gho_path, format="mp3")
        print("  [+] Doubled gho.mp3 successfully!")
    except ImportError:
        print("  [i] pydub not found. Falling back to native ffmpeg engine...")
        gho_temp = os.path.join(BASE, "assets", "audio", "gho_temp.mp3")
        try:
            cmd = ['ffmpeg', '-y', '-i', gho_path, '-filter_complex', '[0:a][0:a]concat=n=2:v=0:a=1', gho_temp]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            os.replace(gho_temp, gho_path)
            print("  [+] Doubled gho.mp3 successfully via ffmpeg!")
        except Exception as e:
            print("  [-] Error running ffmpeg:", e)
            print("  [-] ACTION REQUIRED: Please install pydub ('pip install pydub') or have ffmpeg in your PATH to accomplish the audio doubling.")
            return

    print("\n[!] Task complete! To recalibrate the durations in the JSON file, please run 'python scripts/patch_durations.py' again.")

if __name__ == '__main__':
    main()
