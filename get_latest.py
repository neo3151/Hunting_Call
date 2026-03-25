import os, glob

apks = glob.glob('build/**/*.apk', recursive=True)
if apks:
    apks.sort(key=os.path.getmtime, reverse=True)
    with open('latest_apk_info.txt', 'w') as f:
        f.write(apks[0] + '\n')
