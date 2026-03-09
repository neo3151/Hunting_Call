import librosa
import numpy as np
from pathlib import Path

def is_good_for_training(
    file_path: Path,
    min_snr_db: float = 15.0,      # research-backed minimum
    min_duration: float = 3.0,
    max_duration: float = 30.0
):
    try:
        y, sr = librosa.load(str(file_path), sr=None, mono=True)  # force mono for consistency
        duration = len(y) / sr
        
        if not (min_duration <= duration <= max_duration):
            return False, f"wrong duration ({duration:.1f}s)"
        
        # SNR calculation (bottom 5% as noise floor — standard in bioacoustics)
        rms = np.sqrt(np.mean(y**2))
        if rms < 1e-6:
            return False, "silent file"
        noise_floor = np.percentile(np.abs(y), 5)
        snr = 20 * np.log10(rms / (noise_floor + 1e-8))
        
        if snr < min_snr_db:
            return False, f"SNR too low ({snr:.1f}dB)"
        
        # Clipping check (distortion)
        if np.max(np.abs(y)) > 0.98:
            return False, "clipped/distorted"
        
        return True, f"GOOD (SNR {snr:.1f}dB, {duration:.1f}s)"
    
    except Exception as e:
        return False, f"corrupted or unreadable ({str(e)[:100]})"

if __name__ == "__main__":
    # === HOW TO RUN ===
    good_files = []
    bad_files = []
    folder = Path("downloads/")  # change to your download folder
    
    # Ensure the directory exists to avoid errors on run
    if not folder.exists():
        print(f"Directory {folder} does not exist. Please create it and add .wav files.")
    else:
        for f in folder.rglob("*.wav"):
            ok, reason = is_good_for_training(f)
            if ok:
                good_files.append(f)
            else:
                bad_files.append((f, reason))
                print(f"REJECTED {f.name}: {reason}")
        
        print(f"\n✅ KEPT {len(good_files)} / {len(good_files)+len(bad_files)} files")
        print(f"Ready for fine-tuning or CloudAudioService reference folder!")
