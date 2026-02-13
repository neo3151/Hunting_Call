"""Find the exact audio asset IDs used on the All About Birds Barred Owl sounds page."""
import urllib.request
import re
import json

url = 'https://www.allaboutbirds.org/guide/Barred_Owl/sounds'
req = urllib.request.Request(url, headers={
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
})
resp = urllib.request.urlopen(req, timeout=30)
html = resp.read().decode('utf-8')

# Save raw HTML for inspection
with open(r'c:\Users\neo31\Hunting_Call\assets\audio\raw\aab_barred_owl_page.html', 'w', encoding='utf-8') as f:
    f.write(html)

print(f"Page length: {len(html)} chars")

# Look for asset IDs - typically 6-9 digit numbers near audio/media references
asset_pattern = re.findall(r'(\d{6,9})', html)
# Count occurrences to find which IDs appear most (likely the featured ones)
from collections import Counter
counts = Counter(asset_pattern)
print("\nMost common large numbers (potential asset IDs):")
for num, count in counts.most_common(20):
    print(f"  {num}: {count} times")

# Look for any JSON data blocks
json_blocks = re.findall(r'<script[^>]*type="application/json"[^>]*>(.*?)</script>', html, re.DOTALL)
print(f"\nFound {len(json_blocks)} JSON script blocks")
for i, block in enumerate(json_blocks):
    if 'audio' in block.lower() or 'asset' in block.lower() or 'media' in block.lower():
        print(f"\n--- JSON block {i} (first 500 chars) ---")
        print(block[:500])

# Look for Next.js data or similar
next_data = re.findall(r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>', html, re.DOTALL)
if next_data:
    print("\n--- Found Next.js data ---")
    try:
        data = json.loads(next_data[0])
        print(json.dumps(data, indent=2)[:2000])
    except:
        print(next_data[0][:2000])

# Look for any data-* attributes with numbers
data_attrs = re.findall(r'data-[\w-]+=["\']([\d]+)["\']', html)
print(f"\nData attributes with numbers: {data_attrs[:20]}")

# Look for cornell CDN references
cdn_refs = re.findall(r'cdn[^"\'>\s]{10,80}', html)
print(f"\nCDN references: {cdn_refs[:10]}")

# Look for ML/macaulay references
ml_refs = re.findall(r'macaulay[^"\'>\s]{5,100}', html, re.IGNORECASE)
print(f"\nMacaulay refs: {ml_refs[:10]}")
