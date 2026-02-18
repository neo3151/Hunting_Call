#!/usr/bin/env python3
"""Upload a file to Google Drive (pongownsyou@gmail.com)."""

import sys
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Need file scope (not readonly) to upload
SCOPES = ['https://www.googleapis.com/auth/drive.file']
TARGET_ACCOUNT = 'pongownsyou@gmail.com'

SCRIPT_DIR = Path(__file__).parent
CREDENTIALS_FILE = SCRIPT_DIR / 'gdrive_credentials.json'
TOKEN_FILE = SCRIPT_DIR / 'gdrive_upload_token.json'  # separate token for write access


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
    if len(sys.argv) < 2:
        print("Usage: python gdrive_upload.py <file_path>")
        sys.exit(1)

    file_path = Path(sys.argv[1])
    if not file_path.exists():
        print(f"File not found: {file_path}")
        sys.exit(1)

    service = authenticate()

    print(f"Uploading {file_path.name} ({file_path.stat().st_size / 1024 / 1024:.1f} MB)...")

    file_metadata = {'name': file_path.name}
    media = MediaFileUpload(
        str(file_path),
        mimetype='application/vnd.android.package-archive',
        resumable=True,
    )

    request = service.files().create(body=file_metadata, media_body=media, fields='id,name,webViewLink')

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            pct = int(status.progress() * 100)
            print(f"  {pct}%")

    print(f"\nUploaded! File ID: {response['id']}")
    print(f"Link: {response.get('webViewLink', 'N/A')}")


if __name__ == '__main__':
    main()
