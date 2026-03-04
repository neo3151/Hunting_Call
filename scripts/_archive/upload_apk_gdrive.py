"""Upload APK to Google Drive (Benchmark Apps folder)."""
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

    # Find "Benchmark Apps" folder
    results = service.files().list(
        q="name='Benchmark Apps' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces="drive",
        fields="files(id, name)"
    ).execute()
    folders = results.get("files", [])

    if not folders:
        # Create Benchmark Apps folder
        print("Creating 'Benchmark Apps' folder...")
        folder_meta = {
            "name": "Benchmark Apps",
            "mimeType": "application/vnd.google-apps.folder"
        }
        folder = service.files().create(body=folder_meta, fields="id").execute()
        folder_id = folder["id"]
    else:
        folder_id = folders[0]["id"]
        print(f"Found 'Benchmark Apps' folder: {folder_id}")

    # Upload APK
    apk_path = os.path.join(script_dir, "..", "build", "app", "outputs", "flutter-apk", "app-release.apk")
    apk_path = os.path.abspath(apk_path)

    if not os.path.exists(apk_path):
        print(f"ERROR: APK not found at {apk_path}")
        return

    size_mb = os.path.getsize(apk_path) / (1024 * 1024)
    print(f"Uploading: {apk_path} ({size_mb:.1f} MB)")

    # Check if file already exists in folder, update if so
    existing = service.files().list(
        q=f"name='app-release.apk' and '{folder_id}' in parents and trashed=false",
        fields="files(id, name)"
    ).execute().get("files", [])

    media = MediaFileUpload(apk_path, mimetype="application/vnd.android.package-archive", resumable=True)

    if existing:
        # Update existing file
        file_id = existing[0]["id"]
        print(f"Updating existing file: {file_id}")
        file = service.files().update(
            fileId=file_id,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()
    else:
        # Create new file
        file_meta = {
            "name": "app-release.apk",
            "parents": [folder_id]
        }
        file = service.files().create(
            body=file_meta,
            media_body=media,
            fields="id, name, webViewLink"
        ).execute()

    print(f"\nUpload complete!")
    print(f"   File ID: {file.get('id')}")
    print(f"   Link: {file.get('webViewLink', 'N/A')}")


if __name__ == "__main__":
    main()
