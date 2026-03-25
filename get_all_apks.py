import os, time
from datetime import datetime

apks = []
for root, dirs, files in os.walk('.'):
    if '.git' in root or 'node_modules' in root:
        continue
    for f in files:
        if f.endswith('.apk'):
            path = os.path.join(root, f)
            try:
                mtime = os.path.getmtime(path)
                apks.append((path, mtime))
            except Exception:
                pass

apks.sort(key=lambda x: x[1], reverse=True)
with open("all_apks.txt", "w") as out:
    for path, mtime in apks[:15]:
        dt = datetime.fromtimestamp(mtime).strftime('%Y-%m-%d %H:%M:%S')
        out.write(f"{dt} -- {path}\n")
