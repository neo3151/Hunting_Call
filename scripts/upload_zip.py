#!/usr/bin/env python3
"""Upload the portable ZIP to Google Drive."""

import os
import sys
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCOPES = ['https://www.googleapis.com/auth/drive.file']

def main():
    print("DEBUG: Starting upload_zip.py")
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    token_path = os.path.join(script_dir, "gdrive_token.json")
    creds_path = os.path.join(script_dir, "gdrive_credentials.json")

    print(f"DEBUG: Token path: {token_path}")
    print(f"DEBUG: Token exists: {os.path.exists(token_path)}")

    creds = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("DEBUG: Refreshing token...")
            creds.refresh(Request())
        else:
            print("DEBUG: Running auth flow...")
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(token_path, 'w') as token:
            token.write(creds.to_json())

    service = build('drive', 'v3', credentials=creds)

    # Find or create "Benchmark Apps" folder
    results = service.files().list(
        q="name='Benchmark Apps' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces='drive',
        fields='files(id, name)'
    ).execute()
    items = results.get('files', [])

    if not items:
        print("Creating 'Benchmark Apps' folder...")
        folder_metadata = {
            'name': 'Benchmark Apps',
            'mimeType': 'application/vnd.google-apps.folder'
        }
        folder = service.files().create(body=folder_metadata, fields='id').execute()
        benchmark_folder_id = folder.get('id')
    else:
        benchmark_folder_id = items[0]['id']
        print(f"Found 'Benchmark Apps': {benchmark_folder_id}")

    # Find or create "Windows Releases" subfolder
    results = service.files().list(
        q=f"name='Windows Releases' and '{benchmark_folder_id}' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces='drive',
        fields='files(id, name)'
    ).execute()
    items = results.get('files', [])

    if not items:
        print("Creating 'Windows Releases' folder...")
        folder_metadata = {
            'name': 'Windows Releases',
            'mimeType': 'application/vnd.google-apps.folder',
            'parents': [benchmark_folder_id]
        }
        folder = service.files().create(body=folder_metadata, fields='id').execute()
        windows_folder_id = folder.get('id')
    else:
        windows_folder_id = items[0]['id']
        print(f"Found 'Windows Releases': {windows_folder_id}")

    # Upload ZIP
    zip_path = os.path.join(script_dir, "..", "hunting_calls_portable.zip")
    zip_path = os.path.abspath(zip_path)

    if not os.path.exists(zip_path):
        print(f"ERROR: ZIP not found at {zip_path}")
        return

    size_mb = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"Uploading: {zip_path} ({size_mb:.1f} MB)")

    # Check if file already exists
    results = service.files().list(
        q=f"name='hunting_calls_portable.zip' and '{windows_folder_id}' in parents and trashed=false",
        spaces='drive',
        fields='files(id, name)'
    ).execute()
    existing = results.get('files', [])

    media = MediaFileUpload(zip_path, mimetype='application/zip', resumable=True)

    if existing:
        file_id = existing[0]['id']
        print(f"Updating existing file: {file_id}")
        file = service.files().update(
            fileId=file_id,
            media_body=media
        ).execute()
    else:
        print("Creating new file...")
        file_metadata = {
            'name': 'hunting_calls_portable.zip',
            'parents': [windows_folder_id]
        }
        file = service.files().create(
            body=file_metadata,
            media_body=media,
            fields='id'
        ).execute()

    file_id = file.get('id')
    print(f"\nUpload complete!")
    print(f"   File ID: {file_id}")
    print(f"   Link: https://drive.google.com/file/d/{file_id}/view?usp=drivesdk")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"CRASH: {e}")
        import traceback
        traceback.print_exc()
