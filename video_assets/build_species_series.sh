#!/bin/bash
# ============================================================
# BULK BUILER: 10 Species Deep-Dive Promo Videos
# Duration: ~20-25s | 5 scenes | 1920x1080 @ 30fps
# ============================================================
set -e

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
SERIES_DIR="$BASEDIR/video_assets/species_series"
SCREENSHOTS="$BASEDIR/assets/play_store/screenshots"
FEATURE="$BASEDIR/assets/play_store/feature_graphic.png"

# Common text assets (From Concept 2)
COMMON_TEXT_DIR="$BASEDIR/video_assets/concept2/text"
FONT="/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
WHITE="white"

# associative arrays or pairs
SPECIES=(
  "turkey,Turkey"
  "whitetail,Whitetail"
  "elk,Elk"
  "wolf,Wolf"
  "coyote,Coyote"
  "canada_goose,Canada Goose"
  "wood_duck,Wood Duck"
  "pintail,Pintail"
  "teal,Teal"
  "pheasant,Pheasant"
)

echo "=== Building 10 Species Promo Videos ==="

for item in "${SPECIES[@]}"; do
  IFS=',' read -r DIR_NAME DISPLAY_NAME <<< "$item"
  
  echo ""
  echo "--------------------------------------------------------"
  echo "🎬 Processing: $DISPLAY_NAME ($DIR_NAME)"
  echo "--------------------------------------------------------"

  DIR="$SERIES_DIR/$DIR_NAME"
  TEXTDIR="$DIR/text"
  FRAMEDIR="$DIR/frames"
  HERO="$DIR/hero.png"
  
  mkdir -p "$TEXTDIR" "$FRAMEDIR"
  
  # 1. Copy common text
  cp "$COMMON_TEXT_DIR"/s2_*.png "$TEXTDIR/"
  cp "$COMMON_TEXT_DIR"/s3_*.png "$TEXTDIR/"
  cp "$COMMON_TEXT_DIR"/s4_*.png "$TEXTDIR/"
  cp "$COMMON_TEXT_DIR"/s5_*.png "$TEXTDIR/"

  # 2. Generate custom scene 1 hook for the species
  convert -background none -fill "$WHITE" -font "$FONT" -pointsize 72 \
    -gravity center label:"Think You Can\nCall a $DISPLAY_NAME?" \
    "$TEXTDIR/s1_hook.png"

  # 3. FFMPEG Pipeline
  echo "   [1/5] Scene 1 — Hook..."
  ffmpeg -loglevel error -y -loop 1 -t 4 -i "$HERO" \
    -i "$TEXTDIR/s1_hook.png" \
    -filter_complex \
    "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,
     zoompan=z='min(zoom+0.001,1.2)':d=120:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps=30,
     fade=t=in:st=0:d=0.8[bg];
     [bg][1:v]overlay=(W-w)/2:(H-h)/2:enable='between(t,0.5,3.8)'[out]" \
    -map "[out]" -c:v libx264 -pix_fmt yuv420p -t 4 "$FRAMEDIR/scene_01_hook.mp4"

  echo "   [2/5] Scene 2 — Library..."
  ffmpeg -loglevel error -y -loop 1 -t 5 -i "$SCREENSHOTS/02_library_hires.png" \
    -i "$TEXTDIR/s2_study_title.png" -i "$TEXTDIR/s2_study_sub.png" \
    -filter_complex \
    "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
     [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/5*(ih-1080)), ih-1080)'[fg];
     [bg][fg]overlay=(W-w)/2:(H-h)/2[base];
     [base][1:v]overlay=(W-w)/2:80:enable='between(t,0.5,4.5)'[v1];
     [v1][2:v]overlay=(W-w)/2:920:enable='between(t,1.0,4.5)'[out]" \
    -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_02_library.mp4"

  echo "   [3/5] Scene 3 — Practice..."
  ffmpeg -loglevel error -y -loop 1 -t 5 -i "$SCREENSHOTS/03_practice_hires.png" \
    -i "$TEXTDIR/s3_practice_title.png" -i "$TEXTDIR/s3_practice_sub.png" \
    -filter_complex \
    "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg];
     [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/5*(ih-1080)), ih-1080)'[fg];
     [bg][fg]overlay=(W-w)/2:(H-h)/2[base];
     [base][1:v]overlay=(W-w)/2:80:enable='between(t,0.5,4.5)'[v1];
     [v1][2:v]overlay=(W-w)/2:920:enable='between(t,1.0,4.5)'[out]" \
    -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_03_practice.mp4"

  echo "   [4/5] Scene 4 — Score..."
  ffmpeg -loglevel error -y -loop 1 -t 5 -i "$SCREENSHOTS/06_call_detail_hires.png" \
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

  echo "   [5/5] Scene 5 — CTA..."
  ffmpeg -loglevel error -y -loop 1 -t 5 -i "$FEATURE" \
    -i "$TEXTDIR/s5_cta_title.png" -i "$TEXTDIR/s5_cta_sub.png" \
    -filter_complex \
    "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:#121212,
     fade=t=in:st=0:d=1[bg];
     [bg][1:v]overlay=(W-w)/2:400:enable='between(t,0.8,5)'[v1];
     [v1][2:v]overlay=(W-w)/2:550:enable='between(t,1.3,5)'[out]" \
    -map "[out]" -c:v libx264 -pix_fmt yuv420p "$FRAMEDIR/scene_05_cta.mp4"

  # 4. Concatenate
  echo "   [Concat] Assembling final video..."
  cat > "$FRAMEDIR/concat.txt" << EOF
file 'scene_01_hook.mp4'
file 'scene_02_library.mp4'
file 'scene_03_practice.mp4'
file 'scene_04_score.mp4'
file 'scene_05_cta.mp4'
EOF

  OUTFILE="$DIR/OUTCALL_Promo_${DIR_NAME}.mp4"
  ffmpeg -loglevel error -y -f concat -safe 0 -i "$FRAMEDIR/concat.txt" \
    -c:v copy \
    "$OUTFILE"

  echo "   ✅ Output saved: $OUTFILE"

done

echo ""
echo "=== 🎉 PRODUCTION COMPLETE ==="
