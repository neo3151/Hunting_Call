"""Upload Windows EXE to Google Drive (Windows Releases folder)."""
import os
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCOPES = ["https://www.googleapis.com/auth/drive.file", "https://www.googleapis.com/auth/drive"]

def main():
    print("DEBUG: Starting upload_exe_v2.py")
    script_dir = os.path.dirname(__file__)
    token_path = os.path.join(script_dir, "gdrive_token.json")
    creds_path = os.path.join(script_dir, "gdrive_credentials.json")

    creds = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("DEBUG: Refreshing token...")
            creds.refresh(Request())
            with open(token_path, "w") as f:
                f.write(creds.to_json())
        else:
            print("DEBUG: Asking for new token...")
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
    
    if not folders:
        print("Creating 'Benchmark Apps' folder...")
        folder_meta = {"name": "Benchmark Apps", "mimeType": "application/vnd.google-apps.folder"}
        folder = service.files().create(body=folder_meta, fields="id").execute()
        parent_id = folder["id"]
    else:
        parent_id = folders[0]["id"]
        print(f"Found 'Benchmark Apps': {parent_id}")

    # 2. Find or Create "Windows Releases" inside "Benchmark Apps"
    results = service.files().list(
        q=f"name='Windows Releases' and '{parent_id}' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces="drive",
        fields="files(id, name)"
    ).execute()
    folders = results.get("files", [])

    if not folders:
        print("Creating 'Windows Releases' folder...")
        folder_meta = {
            "name": "Windows Releases",
            "parents": [parent_id],
            "mimeType": "application/vnd.google-apps.folder"
        }
        folder = service.files().create(body=folder_meta, fields="id").execute()
        target_folder_id = folder["id"]
    else:
        target_folder_id = folders[0]["id"]
        print(f"Found 'Windows Releases': {target_folder_id}")

    # 3. Upload EXE
    # Path relative to script: ../build/windows/x64/runner/Release/hunting_calls_perfection.exe
    exe_path = os.path.join(script_dir, "..", "build", "windows", "x64", "runner", "Release", "hunting_calls_perfection.exe")
    exe_path = os.path.abspath(exe_path)

    if not os.path.exists(exe_path):
        print(f"ERROR: EXE not found at {exe_path}")
        return

    size_mb = os.path.getsize(exe_path) / (1024 * 1024)
    print(f"Uploading: {exe_path} ({size_mb:.1f} MB)")

    # Check existing
    existing = service.files().list(
        q=f"name='hunting_calls_perfection.exe' and '{target_folder_id}' in parents and trashed=false",
        fields="files(id, name)"
    ).execute().get("files", [])

    media = MediaFileUpload(exe_path, mimetype="application/vnd.microsoft.portable-executable", resumable=True)

    if existing:
        file_id = existing[0]["id"]
        print(f"Updating existing file: {file_id}")
        file = service.files().update(
            fileId=file_id,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()
    else:
        print("Creating new file...")
        file_meta = {
            "name": "hunting_calls_perfection.exe",
            "parents": [target_folder_id]
        }
        file = service.files().create(
            body=file_meta,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()

    print(f"\nUpload complete!")
    print(f"   Link: {file.get('webViewLink', 'N/A')}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"CRASH: {e}")
        import traceback
        traceback.print_exc()
