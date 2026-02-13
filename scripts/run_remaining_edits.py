"""Run the remaining 2 batch edits that weren't applied."""
import subprocess, shutil, os

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"

def concat_with_self(filename, description, gap_sec=0.3):
    src = os.path.join(AUDIO, filename)
    if not os.path.exists(src):
        print(f"SKIP: {filename} not found")
        return

    trimmed = os.path.join(AUDIO, f"_trimmed_{filename}")
    shutil.copy2(src, trimmed)

    silence = os.path.join(AUDIO, "_silence.mp3")
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
        "-t", str(gap_sec), "-b:a", "192k", silence
    ], capture_output=True, timeout=10)

    concat_list = os.path.join(AUDIO, "_concat.txt")
    with open(concat_list, "w") as f:
        f.write(f"file '{trimmed}'\n")
        f.write(f"file '{silence}'\n")
        f.write(f"file '{trimmed}'\n")

    tmp_out = os.path.join(AUDIO, f"_concat_{filename}")
    subprocess.run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_list,
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ac", "1", "-ar", "44100", "-b:a", "192k", tmp_out
    ], capture_output=True, timeout=30)

    for cleanup in [trimmed, silence, concat_list]:
        if os.path.exists(cleanup):
            os.unlink(cleanup)

    if os.path.exists(tmp_out) and os.path.getsize(tmp_out) > 1000:
        os.replace(tmp_out, src)
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", src],
            capture_output=True, text=True, timeout=5
        )
        new_dur = round(float(r.stdout.strip()), 1)
        sz = os.path.getsize(src) // 1024
        print(f"OK  {filename:30s} -> {new_dur}s ({sz}KB) | {description}")
    else:
        if os.path.exists(tmp_out):
            os.unlink(tmp_out)
        print(f"FAIL {filename:30s} | {description}")


if __name__ == "__main__":
    concat_with_self("bobcat_growl_v2.mp3", "Repeat 1x")
    concat_with_self("bobcat_howl.mp3", "Repeat & isolate")
