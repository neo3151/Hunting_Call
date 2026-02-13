"""Upload Workspace Cleanup to Google Drive."""
import os
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCOPES = ["https://www.googleapis.com/auth/drive.file", "https://www.googleapis.com/auth/drive"]

def main():
    script_dir = os.path.dirname(__file__)
    token_path = os.path.join(script_dir, "gdrive_token.json")
    creds_path = os.path.join(script_dir, "gdrive_credentials.json")

    creds = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(token_path, "w") as f:
                f.write(creds.to_json())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
            with open(token_path, "w") as f:
                f.write(creds.to_json())

    service = build("drive", "v3", credentials=creds)

    # 1. Find or Create "Benchmark Apps"
    results = service.files().list(
        q="name='Benchmark Apps' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces="drive",
        fields="files(id, name)"
    ).execute()
    folders = results.get("files", [])
    parent_id = folders[0]["id"] if folders else None

    if not parent_id:
        print("Creating 'Benchmark Apps' folder...")
        folder_meta = {"name": "Benchmark Apps", "mimeType": "application/vnd.google-apps.folder"}
        folder = service.files().create(body=folder_meta, fields="id").execute()
        parent_id = folder["id"]

    # 2. Find or Create "Workspace Archives"
    results = service.files().list(
        q=f"name='Workspace Archives' and '{parent_id}' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces="drive",
        fields="files(id, name)"
    ).execute()
    folders = results.get("files", [])

    if not folders:
        print("Creating 'Workspace Archives' folder...")
        folder_meta = {
            "name": "Workspace Archives",
            "parents": [parent_id],
            "mimeType": "application/vnd.google-apps.folder"
        }
        folder = service.files().create(body=folder_meta, fields="id").execute()
        target_folder_id = folder["id"]
    else:
        target_folder_id = folders[0]["id"]
        print(f"Found 'Workspace Archives' folder: {target_folder_id}")

    # 3. Upload ZIP
    zip_path = os.path.join(script_dir, "..", "workspace_cleanup.zip")
    zip_path = os.path.abspath(zip_path)

    if not os.path.exists(zip_path):
        print(f"ERROR: Archive not found at {zip_path}")
        return

    size_mb = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"Uploading: {zip_path} ({size_mb:.1f} MB)")

    existing = service.files().list(
        q=f"name='workspace_cleanup.zip' and '{target_folder_id}' in parents and trashed=false",
        fields="files(id, name)"
    ).execute().get("files", [])

    media = MediaFileUpload(zip_path, mimetype="application/zip", resumable=True)

    if existing:
        file_id = existing[0]["id"]
        print(f"Updating existing file: {file_id}")
        file = service.files().update(
            fileId=file_id,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()
    else:
        file_meta = {
            "name": "workspace_cleanup.zip",
            "parents": [target_folder_id]
        }
        file = service.files().create(
            body=file_meta,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()

    print(f"\n✅ Upload complete!")
    print(f"   Link: {file.get('webViewLink', 'N/A')}")
