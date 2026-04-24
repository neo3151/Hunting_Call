#!/bin/bash
# ============================================================
# CONCEPT 5: "Dawn to Dusk" — Cinematic Brand Film
# Duration: ~50s | 7 scenes | 1920x1080 @ 30fps
# ============================================================
set -e

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
TEXTDIR="$BASEDIR/video_assets/concept5/text"
BGDIR="$BASEDIR/video_assets/concept5/bg"
FRAMEDIR="$BASEDIR/video_assets/concept5/frames"
SCREENSHOTS="$BASEDIR/assets/play_store/screenshots"
FEATURE="$BASEDIR/assets/play_store/feature_graphic.png"

echo "=== Building Concept 5: Dawn to Dusk ==="

# ────────────────────────────────────────────────────────────
# Scene 1: Dawn landscape — "4:47 AM" (8s)
# Slow Ken Burns zoom, warm dawn forest, text in/out
# ────────────────────────────────────────────────────────────
echo "[1/7] Scene 1 — Dawn..."
ffmpeg -y -loop 1 -t 8 -i "$BGDIR/dawn_forest.png" \
  -i "$TEXTDIR/s1_dawn.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,
   zoompan=z='min(zoom+0.0008,1.15)':d=240:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps=30,
   fade=t=in:st=0:d=1.5[bg];
   [bg][1:v]overlay=(W-w)/2:(H-h)/2:enable='between(t,1.0,6.5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p -t 8 "$FRAMEDIR/scene_01_dawn.mp4"

# ────────────────────────────────────────────────────────────
# Scene 2: App home screen — "You're Already Prepared" (6s)
# Phone mockup with blurred bg
# ────────────────────────────────────────────────────────────
echo "[2/7] Scene 2 — Home screen..."
ffmpeg -y -loop 1 -t 6 -i "$SCREENSHOTS/01_home_hires.png" \
  -i "$TEXTDIR/s2_prepared.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
   [0:v]scale=540:-1,crop=540:1080:0:0[fg];
   [bg][fg]overlay=(W-w)/2:(H-h)/2,fade=t=in:st=0:d=0.8[base];
   [base][1:v]overlay=(W-w)/2:80:enable='between(t,0.8,5.5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_02_home.mp4"

# ────────────────────────────────────────────────────────────
# Scene 3: Library study — "Cadence, pitch, rhythm" (8s)
# Library screenshot with scroll + text
# ────────────────────────────────────────────────────────────
echo "[3/7] Scene 3 — Study..."
ffmpeg -y -loop 1 -t 8 -i "$SCREENSHOTS/02_library_hires.png" \
  -i "$TEXTDIR/s3_study.png" -i "$TEXTDIR/s3_study_sub.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
   [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/8*(ih-1080)), ih-1080)'[fg];
   [bg][fg]overlay=(W-w)/2:(H-h)/2,fade=t=in:st=0:d=0.6[base];
   [base][1:v]overlay=(W-w)/2:80:enable='between(t,0.5,7.0)'[v1];
   [v1][2:v]overlay=(W-w)/2:920:enable='between(t,1.2,7.0)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_03_study.mp4"

# ────────────────────────────────────────────────────────────
# Scene 4: Practice — "Until it was perfect" (6s)
# Practice screen with waveform
# ────────────────────────────────────────────────────────────
echo "[4/7] Scene 4 — Practice..."
ffmpeg -y -loop 1 -t 6 -i "$SCREENSHOTS/03_practice_hires.png" \
  -i "$TEXTDIR/s4_practiced.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
   [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/6*(ih-1080)), ih-1080)'[fg];
   [bg][fg]overlay=(W-w)/2:(H-h)/2,fade=t=in:st=0:d=0.6[base];
   [base][1:v]overlay=(W-w)/2:80:enable='between(t,0.5,5.5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_04_practice.mp4"

# ────────────────────────────────────────────────────────────
# Scene 5: Score — "And now..." (6s)
# Call detail zoompan, then text overlay
# ────────────────────────────────────────────────────────────
echo "[5/7] Scene 5 — Score reveal..."
ffmpeg -y -loop 1 -t 6 -i "$SCREENSHOTS/06_call_detail_hires.png" \
  -i "$SCREENSHOTS/06_call_detail_hires.png" \
  -i "$TEXTDIR/s5_andnow.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
   [1:v]zoompan=z='min(zoom+0.0015,1.5)':d=180:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=800x1080[fg_raw];
   [fg_raw]scale=540:-1[fg];
   [bg][fg]overlay=(W-w)/2:(H-h)/2:shortest=1,fade=t=in:st=0:d=0.6[base];
   [base][2:v]overlay=(W-w)/2:80:enable='between(t,3.0,5.5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_05_score.mp4"

# ────────────────────────────────────────────────────────────
# Scene 6: Dusk landscape — "...the real thing." (8s)
# Dramatic Ken Burns on sunset landscape with deer
# ────────────────────────────────────────────────────────────
echo "[6/7] Scene 6 — Dusk..."
ffmpeg -y -loop 1 -t 8 -i "$BGDIR/dusk_landscape.png" \
  -i "$TEXTDIR/s6_realthing.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,
   zoompan=z='min(zoom+0.0006,1.12)':d=240:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps=30,
   fade=t=in:st=0:d=1.5[bg];
   [bg][1:v]overlay=(W-w)/2:(H-h)/2:enable='between(t,1.5,7.0)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p -t 8 "$FRAMEDIR/scene_06_dusk.mp4"

# ────────────────────────────────────────────────────────────
# Scene 7: Brand CTA — "Train Like It Matters" (8s)
# Feature graphic with OUTCALL branding
# ────────────────────────────────────────────────────────────
echo "[7/7] Scene 7 — Brand CTA..."
ffmpeg -y -loop 1 -t 8 -i "$FEATURE" \
  -i "$TEXTDIR/s7_brand.png" -i "$TEXTDIR/s7_tagline.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:#121212,
   fade=t=in:st=0:d=1.5,fade=t=out:st=6.5:d=1.5[bg];
   [bg][1:v]overlay=(W-w)/2:350:enable='between(t,1.0,7.0)'[v1];
   [v1][2:v]overlay=(W-w)/2:500:enable='between(t,1.8,7.0)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_07_brand.mp4"

# ────────────────────────────────────────────────────────────
# Concatenate all scenes
# ────────────────────────────────────────────────────────────
echo "=== Concatenating scenes ==="
cat > "$FRAMEDIR/concat.txt" << EOF
file 'scene_01_dawn.mp4'
file 'scene_02_home.mp4'
file 'scene_03_study.mp4'
file 'scene_04_practice.mp4'
file 'scene_05_score.mp4'
file 'scene_06_dusk.mp4'
file 'scene_07_brand.mp4'
EOF

ffmpeg -y -f concat -safe 0 -i "$FRAMEDIR/concat.txt" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
  "$BASEDIR/video_assets/concept5/OUTCALL_Dawn_to_Dusk.mp4"

echo ""
echo "✅ Concept 5 complete: video_assets/concept5/OUTCALL_Dawn_to_Dusk.mp4"
echo "   Duration: ~50s"
