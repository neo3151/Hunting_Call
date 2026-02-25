import os
import sys
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Check if file path and credentials path are provided
if len(sys.argv) < 3:
    print("Usage: python upload_to_drive.py <file_path> <credentials_path>")
    sys.exit(1)

file_path = sys.argv[1]
credentials_path = sys.argv[2]

if not os.path.exists(file_path):
    print(f"Error: File not found: {file_path}")
    sys.exit(1)

if not os.path.exists(credentials_path):
    print(f"Error: Credentials file not found: {credentials_path}")
    sys.exit(1)

# Define the scopes required for Google Drive API
SCOPES = ['https://www.googleapis.com/auth/drive.file']

def authenticate():
    creds = None
    # The file token.json stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    token_path = 'token.json'
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                credentials_path, SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open(token_path, 'w') as token:
            token.write(creds.to_json())
    return creds

try:
    print("Authenticating with Google...")
    creds = authenticate()
    print("Authentication successful.")
    
    # Build the Google Drive API service
    service = build('drive', 'v3', credentials=creds)

    # File metadata
    file_metadata = {'name': os.path.basename(file_path)}
    
    # Media file upload
    media = MediaFileUpload(file_path, resumable=True)

    print(f"Uploading {file_path} to Google Drive...")
    
    # Execute the upload request
    file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
    
    print(f"Upload successful. File ID: {file.get('id')}")

except Exception as e:
    print(f"An error occurred: {e}")
    sys.exit(1)
