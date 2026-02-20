#!/usr/bin/env python3
"""Upload non-free audio files to Firebase Storage using OAuth credentials.

Uses the same credentials.json and token.json from the scripts/ directory
that are used for Gmail API access, but with Firebase Storage scopes.
"""
import os
import sys
import json
import requests

# Free call audio files that are bundled in the APK (do NOT upload these)
FREE_AUDIO_FILES = {
    'duck_mallard_greeting.mp3',
    'duck_mallard_greeting_v2.mp3',
    'goose_canadian_honk.mp3',
    'wood_duck.mp3',
    'deer_buck_grunt.mp3',
    'deer_doe_bleat.mp3',
    'cougar.mp3',
    'coyote_howl.mp3',
    'rabbit_distress.mp3',
    'fox_scream.mp3',
    'turkey_gobble.mp3',
    'crow.mp3',
    'dove.mp3',
    'owl_barred_hoot.mp3',
    'coyote_yip.mp3',
    'awebo.mp3',
}

BUCKET_NAME = 'hunting-call-perfection.firebasestorage.app'
STORAGE_PATH = 'audio/calls'
AUDIO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio')
AUDIO_EXTENSIONS = {'.mp3', '.ogg', '.wav', '.m4a'}

SCOPES = [
    'https://www.googleapis.com/auth/devstorage.read_write',
    'https://www.googleapis.com/auth/firebase.storage',
]


def get_credentials():
    """Get OAuth credentials, refreshing if needed."""
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request

    script_dir = os.path.dirname(os.path.abspath(__file__))
    token_path = os.path.join(script_dir, 'storage_token.json')
    creds_path = os.path.join(script_dir, 'credentials.json')

    creds = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(token_path, 'w') as f:
                f.write(creds.to_json())
        else:
            from google_auth_oauthlib.flow import InstalledAppFlow
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
            with open(token_path, 'w') as f:
                f.write(creds.to_json())

    return creds


def upload_file(creds, local_path, remote_name):
    """Upload a single file to Firebase Storage via Google Cloud Storage JSON API."""
    import urllib.parse
    
    token = creds.token
    encoded_name = urllib.parse.quote(f"{STORAGE_PATH}/{remote_name}", safe='')
    
    # Use GCS JSON API - Firebase Storage buckets are just GCS buckets
    url = f"https://storage.googleapis.com/upload/storage/v1/b/{BUCKET_NAME}/o?uploadType=media&name={STORAGE_PATH}/{remote_name}"
    
    with open(local_path, 'rb') as f:
        data = f.read()
    
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'audio/mpeg',
    }
    
    response = requests.post(url, headers=headers, data=data)
    return response.status_code == 200, response.text


def main():
    audio_dir = os.path.abspath(AUDIO_DIR)
    print(f"Scanning: {audio_dir}")
    print(f"Bucket:   {BUCKET_NAME}")
    print(f"Path:     {STORAGE_PATH}/")
    print()

    # Collect files to upload
    files_to_upload = []
    for f in sorted(os.listdir(audio_dir)):
        ext = os.path.splitext(f)[1].lower()
        if ext not in AUDIO_EXTENSIONS:
            continue
        if f in FREE_AUDIO_FILES:
            print(f"  SKIP (free): {f}")
            continue
        files_to_upload.append(f)

    print(f"\n{len(files_to_upload)} files to upload")
    
    if not files_to_upload:
        print("Nothing to upload!")
        return

    # Authenticate
    print("\nAuthenticating...")
    creds = get_credentials()
    print("✓ Authenticated\n")

    uploaded = 0
    failed = 0
    for f in files_to_upload:
        local_path = os.path.join(audio_dir, f)
        size_kb = os.path.getsize(local_path) // 1024
        
        success, resp = upload_file(creds, local_path, f)
        if success:
            uploaded += 1
            print(f"  ✓ {f} ({size_kb} KB)")
        else:
            failed += 1
            print(f"  ✗ {f}: {resp[:100]}")

    print(f"\n{'='*50}")
    print(f"Uploaded: {uploaded}/{len(files_to_upload)}")
    if failed > 0:
        print(f"Failed:   {failed}")
    else:
        print("All files uploaded successfully! 🎉")


if __name__ == '__main__':
    main()
