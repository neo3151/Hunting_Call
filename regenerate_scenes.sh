#!/bin/bash
set -e

# Scene 3: Analysis (Fix Zoompan duration)
ffmpeg -y -loop 1 -t 5 -i "assets/play_store/screenshots/06_call_detail_hires.png" \
-i "assets/play_store/screenshots/06_call_detail_hires.png" \
-i "video_assets/text/feat2_title.png" -i "video_assets/text/feat2_sub.png" \
-filter_complex \
"[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg]; \
 [1:v]zoompan=z='min(zoom+0.0015,1.5)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=800x1080[fg_raw]; \
 [fg_raw]scale=540:-1[fg]; \
 [bg][fg]overlay=(W-w)/2:(H-h)/2:shortest=1[base]; \
 [base][2:v]overlay=(W-w)/2:100:enable='between(t,0.5,4.5)'[v1]; \
 [v1][3:v]overlay=(W-w)/2:900:enable='between(t,1.0,4.5)'" \
-c:v libx264 -pix_fmt yuv420p video_assets/frames/scene_03_analysis.mp4

# Scene 4: Practice (Regenerate)
ffmpeg -y -loop 1 -t 5 -i "assets/play_store/screenshots/03_practice_hires.png" \
-i "video_assets/text/feat3_title.png" -i "video_assets/text/feat3_sub.png" \
-filter_complex \
"[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg]; \
 [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/5*(ih-1080)), ih-1080)'[fg]; \
 [bg][fg]overlay=(W-w)/2:(H-h)/2[base]; \
 [base][1:v]overlay=(W-w)/2:100:enable='between(t,0.5,4.5)'[v1]; \
 [v1][2:v]overlay=(W-w)/2:900:enable='between(t,1.0,4.5)'" \
-c:v libx264 -pix_fmt yuv420p video_assets/frames/scene_04_practice.mp4

# Scene 5: Progress (Regenerate - Fix crop?)
# t/5*(ih-1080) -> t/5*60.
ffmpeg -y -loop 1 -t 5 -i "assets/play_store/screenshots/04_progress_hires.png" \
-i "video_assets/text/feat4_title.png" -i "video_assets/text/feat4_sub.png" \
-filter_complex \
"[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg]; \
 [0:v]scale=540:-1,crop=540:1080:0:'min(max(0, t/5*60), 60)'[fg]; \
 [bg][fg]overlay=(W-w)/2:(H-h)/2[base]; \
 [base][1:v]overlay=(W-w)/2:100:enable='between(t,0.5,4.5)'[v1]; \
 [v1][2:v]overlay=(W-w)/2:900:enable='between(t,1.0,4.5)'" \
-c:v libx264 -pix_fmt yuv420p video_assets/frames/scene_05_progress.mp4

# Scene 6: Challenge (Regenerate)
ffmpeg -y -loop 1 -t 4 -i "assets/play_store/screenshots/07_daily_challenge_hires.png" \
-i "video_assets/text/feat5_title.png" -i "video_assets/text/feat5_sub.png" \
-filter_complex \
"[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:5[bg]; \
 [0:v]scale=540:-1,crop=540:1080:0:0[fg]; \
 [bg][fg]overlay=(W-w)/2:(H-h)/2[base]; \
 [base][1:v]overlay=(W-w)/2:100:enable='between(t,0.5,3.5)'[v1]; \
 [v1][2:v]overlay=(W-w)/2:900:enable='between(t,0.5,3.5)'" \
-c:v libx264 -pix_fmt yuv420p video_assets/frames/scene_06_challenge.mp4

# Scene 7: Outro (Regenerate)
ffmpeg -y -loop 1 -t 5 -i "assets/play_store/feature_graphic.png" \
-i "video_assets/text/cta_download.png" -i "video_assets/text/cta_store.png" \
-filter_complex \
"[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:#121212,fade=t=in:st=0:d=1[bg]; \
 [bg][1:v]overlay=(W-w)/2:800:enable='between(t,1,5)'[v1]; \
 [v1][2:v]overlay=(W-w)/2:920:enable='between(t,1.5,5)'" \
-c:v libx264 -pix_fmt yuv420p video_assets/frames/scene_07_outro.mp4
