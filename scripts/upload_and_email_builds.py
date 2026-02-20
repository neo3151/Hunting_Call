"""Upload AAB + APK to Google Drive, then email them via Gmail."""
import os, sys, base64, ssl, socket, time
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

# Paths
AAB_PATH = os.path.join(PROJECT_DIR, "build", "app", "outputs", "bundle", "release", "app-release.aab")
APK_PATH = os.path.join(PROJECT_DIR, "build", "app", "outputs", "flutter-apk", "app-release.apk")

# GDrive credentials (pongownsyou@gmail.com)
GDRIVE_TOKEN = os.path.join(SCRIPT_DIR, "gdrive_token.json")
GDRIVE_CREDS = os.path.join(SCRIPT_DIR, "gdrive_credentials.json")
GDRIVE_SCOPES = ["https://www.googleapis.com/auth/drive.file", "https://www.googleapis.com/auth/drive"]

# Gmail credentials (pongownsyou@gmail.com)
GMAIL_TOKEN = os.path.join(SCRIPT_DIR, "token.json")
GMAIL_SCOPES = [
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
]

def get_creds(token_path, scopes):
    creds = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, scopes)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(token_path, "w") as f:
                f.write(creds.to_json())
        else:
            print(f"ERROR: Token expired and cannot refresh. Delete {token_path} and re-auth.")
            sys.exit(1)
    return creds


def upload_to_gdrive(file_path, file_name, mime_type, folder_id, service):
    """Upload or update a file in GDrive folder with retry logic."""
    import time, socket
    
    if not os.path.exists(file_path):
        print(f"ERROR: {file_path} not found!")
        return None

    size_mb = os.path.getsize(file_path) / (1024 * 1024)
    print(f"  Uploading {file_name} ({size_mb:.1f} MB)...")

    # Check if file already exists
    existing = service.files().list(
        q=f"name='{file_name}' and '{folder_id}' in parents and trashed=false",
        fields="files(id, name)"
    ).execute().get("files", [])

    # Use 5MB chunks for resumable upload
    media = MediaFileUpload(file_path, mimetype=mime_type, resumable=True, chunksize=5*1024*1024)

    max_retries = 5
    for attempt in range(max_retries):
        try:
            if existing:
                file_id = existing[0]["id"]
                request = service.files().update(fileId=file_id, media_body=media, fields="id, name, webViewLink")
            else:
                request = service.files().create(
                    body={"name": file_name, "parents": [folder_id]},
                    media_body=media, fields="id, name, webViewLink"
                )
            
            # Execute resumable upload with progress
            response = None
            while response is None:
                try:
                    status, response = request.next_chunk()
                    if status:
                        print(f"    Progress: {int(status.progress() * 100)}%")
                except (ssl.SSLEOFError, socket.error, ConnectionError, Exception) as chunk_err:
                    if "EOF" in str(chunk_err) or "ssl" in str(chunk_err).lower() or "Connection" in str(chunk_err):
                        print(f"    Connection interrupted, retrying chunk...")
                        time.sleep(2)
                        continue
                    raise
            
            action = "Updated" if existing else "Created"
            print(f"  {action}: {response.get('webViewLink', 'N/A')}")
            return response
            
        except Exception as e:
            if attempt < max_retries - 1:
                wait = 2 ** (attempt + 1)
                print(f"  Attempt {attempt+1} failed: {e}")
                print(f"  Retrying in {wait}s...")
                time.sleep(wait)
                # Re-create media object for retry
                media = MediaFileUpload(file_path, mimetype=mime_type, resumable=True, chunksize=5*1024*1024)
            else:
                print(f"  FAILED after {max_retries} attempts: {e}")
                return None


def main():
    # Verify files exist
    for path, name in [(AAB_PATH, "AAB"), (APK_PATH, "APK")]:
        if not os.path.exists(path):
            print(f"ERROR: {name} not found at {path}")
            sys.exit(1)

    # === 1. UPLOAD TO GOOGLE DRIVE ===
    print("\n=== Uploading to Google Drive ===")
    gdrive_creds = get_creds(GDRIVE_TOKEN, GDRIVE_SCOPES)
    drive_service = build("drive", "v3", credentials=gdrive_creds)

    # Find or create "Benchmark Apps" folder
    results = drive_service.files().list(
        q="name='Benchmark Apps' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces="drive", fields="files(id, name)"
    ).execute()
    folders = results.get("files", [])

    if not folders:
        print("Creating 'Benchmark Apps' folder...")
        folder = drive_service.files().create(
            body={"name": "Benchmark Apps", "mimeType": "application/vnd.google-apps.folder"},
            fields="id"
        ).execute()
        folder_id = folder["id"]
    else:
        folder_id = folders[0]["id"]
        print(f"Found 'Benchmark Apps' folder")

    # Upload both files
    aab_result = upload_to_gdrive(AAB_PATH, "app-release.aab", "application/octet-stream", folder_id, drive_service)
    apk_result = upload_to_gdrive(APK_PATH, "app-release.apk", "application/vnd.android.package-archive", folder_id, drive_service)

    print("\nGDrive upload complete!")

    # === 2. SEND EMAIL WITH ATTACHMENTS ===
    print("\n=== Sending Email ===")
    gmail_creds = get_creds(GMAIL_TOKEN, GMAIL_SCOPES)
    gmail_service = build("gmail", "v1", credentials=gmail_creds)

    msg = MIMEMultipart()
    msg["to"] = "benchmarkappsllc@gmail.com"
    msg["from"] = "pongownsyou@gmail.com"
    msg["subject"] = "latest aab and apk, this is automated"

    body = (
        "I had this setup to send while im getting ready for work so hopefully it did what i told it to. "
        "there should be the freshest 1.5.1 apk and aab files after uploading them to the gdrive"
    )
    msg.attach(MIMEText(body))

    # Attach AAB
    aab_size = os.path.getsize(AAB_PATH) / (1024 * 1024)
    apk_size = os.path.getsize(APK_PATH) / (1024 * 1024)

    # Gmail has a 25MB attachment limit per message
    # AAB is 41.7MB and APK is 70.4MB — both exceed the limit
    # We'll include GDrive links instead of raw attachments
    if aab_size > 24 or apk_size > 24:
        print(f"  Files too large for email attachment (AAB: {aab_size:.1f}MB, APK: {apk_size:.1f}MB)")
        print(f"  Including Google Drive links instead...")
        
        # Update body with links
        aab_link = aab_result.get("webViewLink", "N/A") if aab_result else "upload failed"
        apk_link = apk_result.get("webViewLink", "N/A") if apk_result else "upload failed"
        
        body_with_links = (
            f"{body}\n\n"
            f"Google Drive Links:\n"
            f"  AAB ({aab_size:.1f}MB): {aab_link}\n"
            f"  APK ({apk_size:.1f}MB): {apk_link}\n"
            f"\nBoth files are in the 'Benchmark Apps' folder on GDrive."
        )
        
        # Rebuild message with links
        msg = MIMEMultipart()
        msg["to"] = "benchmarkappsllc@gmail.com"
        msg["from"] = "pongownsyou@gmail.com"
        msg["subject"] = "latest aab and apk, this is automated"
        msg.attach(MIMEText(body_with_links))
    else:
        # Attach files directly
        for path, name in [(AAB_PATH, "app-release.aab"), (APK_PATH, "app-release.apk")]:
            with open(path, "rb") as f:
                att = MIMEApplication(f.read())
                att.add_header("Content-Disposition", "attachment", filename=name)
                msg.attach(att)

    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    result = gmail_service.users().messages().send(userId="me", body={"raw": raw}).execute()
    print(f"Email sent! Message ID: {result['id']}")
    print("Done!")


if __name__ == "__main__":
    main()
