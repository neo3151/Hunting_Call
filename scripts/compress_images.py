"""
Batch Image Compressor — PNG to WebP conversion for OUTCALL
Converts oversized PNGs (>200KB) to WebP at quality 85.
Also updates all Dart source files to reference the new .webp extensions.
"""
import os, json, glob, re
from PIL import Image

ASSETS_DIR = r"C:\Users\neo31\Hunting_Call\assets\images"
LIB_DIR = r"C:\Users\neo31\Hunting_Call\lib"
AUDIT_DATA = r"C:\Users\neo31\Hunting_Call\audit_data.json"
SIZE_THRESHOLD_KB = 200
WEBP_QUALITY = 85

# Load audit data to find oversized images
d = json.load(open(AUDIT_DATA))
big_images = [i for i in d["assets"]["image_files"] if i["size_kb"] > SIZE_THRESHOLD_KB]
total = len(big_images)

print(f"[░░░░░░░░░░] 0% | Found {total} images > {SIZE_THRESHOLD_KB}KB to convert")

converted = []
skipped = []
errors = []

for idx, img_info in enumerate(big_images):
    name = img_info["name"]
    base, ext = os.path.splitext(name)
    
    pct = int((idx + 1) / total * 60)
    bar = "█" * (pct // 10) + "░" * (10 - pct // 10)
    print(f"\r[{bar}] {pct}% | {idx+1}/{total} Converting {name}...", end="", flush=True)
    
    # Find the file
    found = None
    for root, _, files in os.walk(ASSETS_DIR):
        if name in files:
            found = os.path.join(root, name)
            break
    
    if not found:
        skipped.append((name, "not found"))
        continue
    
    # Skip if already webp
    if ext.lower() == '.webp':
        skipped.append((name, "already webp"))
        continue
    
    # Skip splash_logo.png (referenced in native splash config)
    if name in ('splash_logo.png',):
        skipped.append((name, "native splash asset - keep PNG"))
        continue
    
    webp_path = os.path.join(os.path.dirname(found), base + ".webp")
    
    try:
        with Image.open(found) as im:
            # Convert RGBA PNGs properly
            im.save(webp_path, 'WEBP', quality=WEBP_QUALITY, method=6)
        
        orig_size = os.path.getsize(found)
        new_size = os.path.getsize(webp_path)
        saving = orig_size - new_size
        
        if new_size < orig_size:
            # Remove original only if WebP is smaller
            os.remove(found)
            converted.append({
                "name": name,
                "new_name": base + ".webp",
                "orig_kb": round(orig_size / 1024, 1),
                "new_kb": round(new_size / 1024, 1),
                "saved_kb": round(saving / 1024, 1),
            })
        else:
            # WebP is larger (rare), keep original
            os.remove(webp_path)
            skipped.append((name, f"webp larger ({new_size}>{orig_size})"))
    except Exception as e:
        errors.append((name, str(e)))

print()
print(f"\n[██████░░░░] 60% | Converted {len(converted)} images. Updating Dart references...")

# Phase 2: Update Dart references
dart_files = []
for root, _, files in os.walk(LIB_DIR):
    for f in files:
        if f.endswith('.dart'):
            dart_files.append(os.path.join(root, f))

updated_files = 0
total_replacements = 0

for idx, dart_path in enumerate(dart_files):
    if (idx + 1) % 20 == 0:
        pct = 60 + int((idx + 1) / len(dart_files) * 30)
        bar = "█" * (pct // 10) + "░" * (10 - pct // 10)
        print(f"\r[{bar}] {pct}% | {idx+1}/{len(dart_files)} Dart files scanned", end="", flush=True)
    
    try:
        with open(dart_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except:
        continue
    
    new_content = content
    file_replacements = 0
    
    for c in converted:
        old_ref = c["name"]
        new_ref = c["new_name"]
        if old_ref in new_content:
            new_content = new_content.replace(old_ref, new_ref)
            file_replacements += new_content.count(new_ref)
    
    if new_content != content:
        with open(dart_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        updated_files += 1
        total_replacements += file_replacements

# Also update pubspec.yaml if needed (asset references)
pubspec_path = r"C:\Users\neo31\Hunting_Call\pubspec.yaml"
try:
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        pubspec = f.read()
    new_pubspec = pubspec
    for c in converted:
        if c["name"] in new_pubspec:
            new_pubspec = new_pubspec.replace(c["name"], c["new_name"])
    if new_pubspec != pubspec:
        with open(pubspec_path, 'w', encoding='utf-8') as f:
            f.write(new_pubspec)
        print("\n  Updated pubspec.yaml references")
except:
    pass

print()
print(f"\n[██████████] 100% | Image compression complete!")
print(f"\n=== RESULTS ===")
print(f"Converted: {len(converted)} images")
print(f"Skipped:   {len(skipped)} images")
print(f"Errors:    {len(errors)} images")
print(f"Dart files updated: {updated_files}")
print(f"Total ref replacements: {total_replacements}")

if converted:
    total_saved = sum(c["saved_kb"] for c in converted)
    print(f"\nTotal savings: {total_saved/1024:.1f} MB")
    print(f"\nTop 10 biggest savings:")
    for c in sorted(converted, key=lambda x: x["saved_kb"], reverse=True)[:10]:
        print(f"  {c['name']:40s} {c['orig_kb']:8.1f} KB → {c['new_kb']:8.1f} KB  (saved {c['saved_kb']:.0f} KB)")

if skipped:
    print(f"\nSkipped:")
    for name, reason in skipped:
        print(f"  {name}: {reason}")

if errors:
    print(f"\nErrors:")
    for name, err in errors:
        print(f"  {name}: {err}")

# Save conversion log
log = {"converted": converted, "skipped": skipped, "errors": errors, 
       "updated_dart_files": updated_files, "total_replacements": total_replacements}
with open(r"C:\Users\neo31\Hunting_Call\image_conversion_log.json", 'w') as f:
    json.dump(log, f, indent=2)
