#!/usr/bin/env python3
"""
Fetch the latest image from Google Drive (pongownsyou@gmail.com).
Re-uses the same OAuth credentials as gdrive_audio_import.py.
"""

import sys
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

SCOPES = ['https://www.googleapis.com/auth/drive.readonly']
TARGET_ACCOUNT = 'pongownsyou@gmail.com'

SCRIPT_DIR = Path(__file__).parent
CREDENTIALS_FILE = SCRIPT_DIR / 'gdrive_credentials.json'
TOKEN_FILE = SCRIPT_DIR / 'gdrive_token.json'
OUTPUT_DIR = Path.home() / 'Downloads'

IMAGE_MIME_TYPES = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/bmp',
    'image/tiff',
    'image/heic',
    'image/heif',
]


def authenticate():
    creds = None
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("Refreshing token...")
            creds.refresh(Request())
        else:
            if not CREDENTIALS_FILE.exists():
                print(f"ERROR: {CREDENTIALS_FILE} not found")
                sys.exit(1)
            print(f"Authorizing — sign in with: {TARGET_ACCOUNT}")
            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_FILE), SCOPES,
            )
            creds = flow.run_local_server(
                port=0,
                login_hint=TARGET_ACCOUNT,
                prompt='consent',
            )
        with open(TOKEN_FILE, 'w') as f:
            f.write(creds.to_json())
        print("Token saved.")

    return build('drive', 'v3', credentials=creds)


def main():
    service = authenticate()

    # Build query for image files
    mime_q = ' or '.join(f"mimeType='{m}'" for m in IMAGE_MIME_TYPES)
    query = f"({mime_q}) and trashed=false"

    print("Searching for the latest image...")
    results = service.files().list(
        q=query,
        fields="files(id, name, mimeType, modifiedTime, createdTime)",
        orderBy="modifiedTime desc",
        pageSize=1,
    ).execute()

    files = results.get('files', [])
    if not files:
        print("No images found in Drive.")
        return

    latest = files[0]
    name = latest['name']
    file_id = latest['id']
    modified = latest.get('modifiedTime', '?')
    created = latest.get('createdTime', '?')

    print(f"\nLatest image: {name}")
    print(f"  Modified:  {modified}")
    print(f"  Created:   {created}")
    print(f"  MIME type: {latest['mimeType']}")

    # Download
    dest = OUTPUT_DIR / name
    print(f"\nDownloading to {dest} ...")

    request = service.files().get_media(fileId=file_id)
    with open(dest, 'wb') as f:
        downloader = MediaIoBaseDownload(f, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
            if status:
                pct = int(status.progress() * 100)
                print(f"  {pct}%")

    size_kb = dest.stat().st_size / 1024
    print(f"\nDone! Saved {name} ({size_kb:.1f} KB) to {dest}")


if __name__ == '__main__':
    main()
