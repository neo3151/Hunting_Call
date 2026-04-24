#!/bin/bash
# ============================================================
# CONCEPT 2: "The Mallard Master" — Species Deep-Dive
# Duration: ~25s | 5 scenes | 1920x1080 @ 30fps
# ============================================================
set -e

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
TEXTDIR="$BASEDIR/video_assets/concept2/text"
FRAMEDIR="$BASEDIR/video_assets/concept2/frames"
SCREENSHOTS="$BASEDIR/assets/play_store/screenshots"
HERO="$BASEDIR/video_assets/concept2/mallard_hero.png"
FEATURE="$BASEDIR/assets/play_store/feature_graphic.png"

echo "=== Building Concept 2: The Mallard Master ==="

# ────────────────────────────────────────────────────────────
# Scene 1: Mallard hero with hook text (4s)
# Ken Burns zoom on the mallard image, text fades in
# ────────────────────────────────────────────────────────────
echo "[1/5] Scene 1 — Hook..."
ffmpeg -y -loop 1 -t 4 -i "$HERO" \
  -i "$TEXTDIR/s1_hook.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,
   zoompan=z='min(zoom+0.001,1.2)':d=120:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps=30,
   fade=t=in:st=0:d=0.8[bg];
   [bg][1:v]overlay=(W-w)/2:(H-h)/2:enable='between(t,0.5,3.8)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p -t 4 "$FRAMEDIR/scene_01_hook.mp4"

# ────────────────────────────────────────────────────────────
# Scene 2: Library — Browse the species (5s)
# Phone screenshot centered on blurred bg
# ────────────────────────────────────────────────────────────
echo "[2/5] Scene 2 — Library..."
ffmpeg -y -loop 1 -t 5 -i "$SCREENSHOTS/02_library_hires.png" \
  -i "$TEXTDIR/s2_study_title.png" -i "$TEXTDIR/s2_study_sub.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
   [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/5*(ih-1080)), ih-1080)'[fg];
   [bg][fg]overlay=(W-w)/2:(H-h)/2[base];
   [base][1:v]overlay=(W-w)/2:80:enable='between(t,0.5,4.5)'[v1];
   [v1][2:v]overlay=(W-w)/2:920:enable='between(t,1.0,4.5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_02_library.mp4"

# ────────────────────────────────────────────────────────────
# Scene 3: Practice — Real-time analysis (5s)
# Phone screenshot with scroll + text overlays
# ────────────────────────────────────────────────────────────
echo "[3/5] Scene 3 — Practice..."
ffmpeg -y -loop 1 -t 5 -i "$SCREENSHOTS/03_practice_hires.png" \
  -i "$TEXTDIR/s3_practice_title.png" -i "$TEXTDIR/s3_practice_sub.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
   [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/5*(ih-1080)), ih-1080)'[fg];
   [bg][fg]overlay=(W-w)/2:(H-h)/2[base];
   [base][1:v]overlay=(W-w)/2:80:enable='between(t,0.5,4.5)'[v1];
   [v1][2:v]overlay=(W-w)/2:920:enable='between(t,1.0,4.5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_03_practice.mp4"

# ────────────────────────────────────────────────────────────
# Scene 4: Score result — Call detail (5s)
# Zoompan on call detail screenshot
# ────────────────────────────────────────────────────────────
echo "[4/5] Scene 4 — Score..."
ffmpeg -y -loop 1 -t 5 -i "$SCREENSHOTS/06_call_detail_hires.png" \
  -i "$SCREENSHOTS/06_call_detail_hires.png" \
  -i "$TEXTDIR/s4_score_title.png" -i "$TEXTDIR/s4_score_sub.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
   [1:v]zoompan=z='min(zoom+0.0015,1.5)':d=150:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=800x1080[fg_raw];
   [fg_raw]scale=540:-1[fg];
   [bg][fg]overlay=(W-w)/2:(H-h)/2:shortest=1[base];
   [base][2:v]overlay=(W-w)/2:80:enable='between(t,0.5,4.5)'[v1];
   [v1][3:v]overlay=(W-w)/2:920:enable='between(t,1.0,4.5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_04_score.mp4"

# ────────────────────────────────────────────────────────────
# Scene 5: CTA outro (5s)
# Feature graphic with download CTA
# ────────────────────────────────────────────────────────────
echo "[5/5] Scene 5 — CTA..."
ffmpeg -y -loop 1 -t 5 -i "$FEATURE" \
  -i "$TEXTDIR/s5_cta_title.png" -i "$TEXTDIR/s5_cta_sub.png" \
  -filter_complex \
  "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:#121212,
   fade=t=in:st=0:d=1[bg];
   [bg][1:v]overlay=(W-w)/2:400:enable='between(t,0.8,5)'[v1];
   [v1][2:v]overlay=(W-w)/2:550:enable='between(t,1.3,5)'[out]" \
  -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_05_cta.mp4"

# ────────────────────────────────────────────────────────────
# Concatenate all scenes
# ────────────────────────────────────────────────────────────
echo "=== Concatenating scenes ==="
cat > "$FRAMEDIR/concat.txt" << EOF
file 'scene_01_hook.mp4'
file 'scene_02_library.mp4'
file 'scene_03_practice.mp4'
file 'scene_04_score.mp4'
file 'scene_05_cta.mp4'
EOF

ffmpeg -y -f concat -safe 0 -i "$FRAMEDIR/concat.txt" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
  "$BASEDIR/video_assets/concept2/OUTCALL_Mallard_Master.mp4"

echo ""
echo "✅ Concept 2 complete: video_assets/concept2/OUTCALL_Mallard_Master.mp4"
echo "   Duration: ~24s"
