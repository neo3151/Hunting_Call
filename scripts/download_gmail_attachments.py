"""
Download attachments from Gmail 'In app calls' label.
Usage: python scripts/download_gmail_attachments.py [output_dir]

Uses credentials.json for OAuth and stores gmail_token.json for session reuse.
"""
import os
import sys
import base64
from pathlib import Path
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']
CREDENTIALS_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'credentials.json')
TOKEN_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'gmail_token.json')

def authenticate():
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    return creds

def get_label_id(service, label_name):
    """Find the label ID for a given label name."""
    results = service.users().labels().list(userId='me').execute()
    for label in results.get('labels', []):
        if label['name'] == label_name:
            return label['id']
    return None

def download_attachments(service, output_dir):
    """Download all attachments from emails in the 'In app calls' label."""
    label_id = get_label_id(service, 'In app calls')
    if not label_id:
        print("ERROR: 'In app calls' label not found!")
        print("Available labels:")
        results = service.users().labels().list(userId='me').execute()
        for label in results.get('labels', []):
            if label['type'] == 'user':
                print(f"  - {label['name']}")
        return

    print(f"Found label 'In app calls' (ID: {label_id})")

    # Get all messages in this label
    results = service.users().messages().list(userId='me', labelIds=[label_id]).execute()
    messages = results.get('messages', [])
    print(f"Found {len(messages)} messages in label")

    os.makedirs(output_dir, exist_ok=True)
    downloaded = []

    for msg_info in messages:
        msg = service.users().messages().get(userId='me', id=msg_info['id']).execute()
        
        # Get subject
        headers = msg.get('payload', {}).get('headers', [])
        subject = next((h['value'] for h in headers if h['name'] == 'Subject'), '(no subject)')
        date = next((h['value'] for h in headers if h['name'] == 'Date'), '(no date)')
        print(f"\n--- Message: {subject} ({date}) ---")

        # Get body text
        payload = msg.get('payload', {})
        body_text = _extract_body(payload)
        if body_text:
            print(f"  Body: {body_text[:200]}")

        # Find and download attachments
        parts = payload.get('parts', [])
        for part in parts:
            _download_parts(service, msg_info['id'], part, output_dir, downloaded)

    print(f"\n=== Downloaded {len(downloaded)} attachments to {output_dir} ===")
    for f in downloaded:
        size_mb = os.path.getsize(f) / (1024 * 1024)
        print(f"  {os.path.basename(f)} ({size_mb:.1f} MB)")

def _extract_body(payload):
    """Extract plain text body from message payload."""
    if payload.get('mimeType') == 'text/plain':
        data = payload.get('body', {}).get('data', '')
        if data:
            return base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')
    for part in payload.get('parts', []):
        text = _extract_body(part)
        if text:
            return text
    return None

def _download_parts(service, msg_id, part, output_dir, downloaded):
    """Recursively find and download attachment parts."""
    filename = part.get('filename', '')
    if filename and part.get('body', {}).get('attachmentId'):
        att_id = part['body']['attachmentId']
        print(f"  Downloading: {filename} ...")
        att = service.users().messages().attachments().get(
            userId='me', id=att_id, messageId=msg_id
        ).execute()
        data = base64.urlsafe_b64decode(att['data'])
        filepath = os.path.join(output_dir, filename)
        
        # Avoid duplicates
        if os.path.exists(filepath):
            base, ext = os.path.splitext(filename)
            i = 1
            while os.path.exists(filepath):
                filepath = os.path.join(output_dir, f"{base}_{i}{ext}")
                i += 1
        
        with open(filepath, 'wb') as f:
            f.write(data)
        downloaded.append(filepath)
        print(f"    -> Saved: {filepath}")

    # Recurse into nested parts
    for sub_part in part.get('parts', []):
        _download_parts(service, msg_id, sub_part, output_dir, downloaded)


if __name__ == '__main__':
    output_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.dirname(__file__)), 'assets', 'audio', '_gmail_imports'
    )
    
    print("Authenticating with Gmail API...")
    creds = authenticate()
    service = build('gmail', 'v1', credentials=creds)
    print("Authenticated successfully.\n")
    
    download_attachments(service, output_dir)
