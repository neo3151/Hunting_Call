#!/usr/bin/env python3
"""Upload Play Store screenshots and feature graphic to Google Drive."""
import os
import sys
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCOPES = ["https://www.googleapis.com/auth/drive.file", "https://www.googleapis.com/auth/drive"]

def authenticate():
    script_dir = Path(__file__).parent
    token_path = script_dir / "gdrive_token.json"
    creds_path = script_dir / "gdrive_credentials.json"

    creds = None
    if token_path.exists():
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("Refreshing token...")
            creds.refresh(Request())
            with open(token_path, "w") as f:
                f.write(creds.to_json())
        else:
            print("Authorizing new token...")
            flow = InstalledAppFlow.from_client_secrets_file(str(creds_path), SCOPES)
            creds = flow.run_local_server(port=0)
            with open(token_path, "w") as f:
                f.write(creds.to_json())

    return build("drive", "v3", credentials=creds)

def find_or_create_folder(service, folder_name, parent_id=None):
    query = f"name='{folder_name}' and mimeType='application/vnd.google-apps.folder' and trashed=false"
    if parent_id:
        query += f" and '{parent_id}' in parents"
    
    results = service.files().list(q=query, spaces="drive", fields="files(id, name)").execute()
    folders = results.get("files", [])

    if folders:
        print(f"  Found folder: {folder_name} ({folders[0]['id']})")
        return folders[0]["id"]
    
    print(f"  Creating folder: {folder_name}...")
    folder_meta = {
        "name": folder_name,
        "mimeType": "application/vnd.google-apps.folder"
    }
    if parent_id:
        folder_meta["parents"] = [parent_id]
        
    folder = service.files().create(body=folder_meta, fields="id").execute()
    return folder["id"]

def upload_file(service, file_path, folder_id):
    file_path = Path(file_path)
    if not file_path.exists():
        print(f"  ERROR: File not found: {file_path}")
        return None

    print(f"  Uploading {file_path.name}...")
    
    # Check if file exists
    existing = service.files().list(
        q=f"name='{file_path.name}' and '{folder_id}' in parents and trashed=false",
        fields="files(id, name)"
    ).execute().get("files", [])

    media = MediaFileUpload(str(file_path), mimetype="image/png", resumable=True)

    if existing:
        file_id = existing[0]["id"]
        print(f"    Updating existing file: {file_id}")
        file = service.files().update(
            fileId=file_id,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()
    else:
        file_meta = {
            "name": file_path.name,
            "parents": [folder_id]
        }
        file = service.files().create(
            body=file_meta,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()
        
    return file.get("webViewLink")

def main():
    service = authenticate()
    
    print("--- Setting up folders ---")
    benchmark_id = find_or_create_folder(service, "Benchmark Apps")
    outcall_assets_id = find_or_create_folder(service, "OUTCALL Play Store Assets", benchmark_id)
    
    print("\n--- Uploading Assets ---")
    base_dir = Path(__file__).parent.parent / "assets" / "play_store"
    
    files_to_upload = []
    # Screenshots
    ss_dir = base_dir / "screenshots"
    for f in ss_dir.glob("*_hires.png"):
        files_to_upload.append(f)
    
    # Feature graphic
    fg = base_dir / "feature_graphic.png"
    if fg.exists():
        files_to_upload.append(fg)
        
    links = []
    for f in sorted(files_to_upload):
        link = upload_file(service, f, outcall_assets_id)
        if link:
            links.append((f.name, link))
            
    print("\n--- Complete! ---")
    print(f"View folder: https://drive.google.com/drive/folders/{outcall_assets_id}")
    for name, link in links:
        print(f"  {name}: {link}")

if __name__ == "__main__":
    main()
