#!/usr/bin/env python3
"""
Gmail Audio Import Script
=========================
Pulls audio attachments (.wav, .mp3) from the 'Animal Sounds' Gmail label
and saves email body notes as .md files alongside them.

Target account: benchmarkappsllc@gmail.com

Setup:
  1. Go to https://console.cloud.google.com/
  2. Create/select a project -> Enable "Gmail API"
  3. Create OAuth 2.0 Client ID (Desktop app type)
  4. Download credentials.json -> place in this scripts/ directory
  5. pip install -r requirements-gmail.txt
  6. python gmail_audio_import.py
"""

import os
import sys
import re
import base64
import email
from datetime import datetime
from pathlib import Path
from html.parser import HTMLParser

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# --- Configuration ---
SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']
TARGET_ACCOUNT = 'benchmarkappsllc@gmail.com'
LABEL_NAME = 'Animal Sounds'
AUDIO_EXTENSIONS = {'.wav', '.mp3'}

# Paths (relative to this script's location)
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
OUTPUT_DIR = PROJECT_ROOT / 'assets' / 'audio' / 'gmail_imports'
CREDENTIALS_FILE = SCRIPT_DIR / 'credentials.json'
TOKEN_FILE = SCRIPT_DIR / 'gmail_token.json'


class HTMLTextExtractor(HTMLParser):
    """Simple HTML to text converter."""
    def __init__(self):
        super().__init__()
        self._text = []
        self._skip = False

    def handle_starttag(self, tag, attrs):
        if tag in ('style', 'script'):
            self._skip = True
        elif tag == 'br':
            self._text.append('\n')
        elif tag in ('p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li'):
            self._text.append('\n')

    def handle_endtag(self, tag):
        if tag in ('style', 'script'):
            self._skip = False
        elif tag in ('p', 'div'):
            self._text.append('\n')

    def handle_data(self, data):
        if not self._skip:
            self._text.append(data)

    def get_text(self):
        text = ''.join(self._text)
        # Collapse excessive blank lines
        text = re.sub(r'\n{3,}', '\n\n', text)
        return text.strip()


def html_to_text(html_content: str) -> str:
    """Convert HTML email body to plain text."""
    extractor = HTMLTextExtractor()
    extractor.feed(html_content)
    return extractor.get_text()


def sanitize_filename(name: str) -> str:
    """Remove invalid characters from a filename."""
    name = re.sub(r'[<>:"/\\|?*]', '_', name)
    name = re.sub(r'\s+', '_', name)
    name = re.sub(r'_+', '_', name)
    return name.strip('_. ')


def authenticate():
    """Authenticate with Gmail API using OAuth."""
    creds = None

    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("🔄 Refreshing expired token...")
            creds.refresh(Request())
        else:
            if not CREDENTIALS_FILE.exists():
                print(f"❌ credentials.json not found at: {CREDENTIALS_FILE}")
                print(f"\nSetup instructions:")
                print(f"  1. Go to https://console.cloud.google.com/")
                print(f"  2. Create/select a project → Enable 'Gmail API'")
                print(f"  3. Create OAuth 2.0 Client ID (Desktop app type)")
                print(f"  4. Download credentials.json → place in {SCRIPT_DIR}")
                sys.exit(1)

            print(f"🔐 Authorizing with Gmail API...")
            print(f"   Please sign in with: {TARGET_ACCOUNT}")
            print(f"   A browser window will open for authorization.\n")

            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_FILE), SCOPES,
            )
            creds = flow.run_local_server(
                port=0,
                login_hint=TARGET_ACCOUNT,
                prompt='consent',
            )

        # Save token for future runs
        with open(TOKEN_FILE, 'w') as f:
            f.write(creds.to_json())
        print("✅ Token saved for future use.")

    return build('gmail', 'v1', credentials=creds)


def find_label_id(service, label_name: str) -> str:
    """Find the Gmail label ID by name."""
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])

    for label in labels:
        if label['name'].lower() == label_name.lower():
            return label['id']

    # Show available labels to help debug
    print(f"❌ Label '{label_name}' not found. Available labels:")
    for label in sorted(labels, key=lambda l: l['name']):
        if label['type'] == 'user':
            print(f"   - {label['name']}")
    sys.exit(1)


def get_email_body(payload) -> str:
    """Extract the email body text from the message payload."""
    body_text = ""
    body_html = ""

    if 'parts' in payload:
        for part in payload['parts']:
            mime_type = part.get('mimeType', '')

            if mime_type == 'text/plain':
                data = part.get('body', {}).get('data', '')
                if data:
                    body_text = base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')

            elif mime_type == 'text/html':
                data = part.get('body', {}).get('data', '')
                if data:
                    body_html = base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')

            elif mime_type.startswith('multipart/'):
                # Recurse into nested multipart
                nested = get_email_body(part)
                if nested and not body_text:
                    body_text = nested

    elif payload.get('mimeType') == 'text/plain':
        data = payload.get('body', {}).get('data', '')
        if data:
            body_text = base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')

    elif payload.get('mimeType') == 'text/html':
        data = payload.get('body', {}).get('data', '')
        if data:
            body_html = base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')

    # Prefer plain text, fall back to HTML converted to text
    if body_text.strip():
        return body_text.strip()
    elif body_html.strip():
        return html_to_text(body_html)
    return ""


def get_attachments_info(payload) -> list:
    """Get list of audio attachment info from message payload."""
    attachments = []

    if 'parts' in payload:
        for part in payload['parts']:
            filename = part.get('filename', '')
            if filename:
                ext = Path(filename).suffix.lower()
                if ext in AUDIO_EXTENSIONS:
                    att_id = part.get('body', {}).get('attachmentId', '')
                    size = int(part.get('body', {}).get('size', 0))
                    attachments.append({
                        'filename': filename,
                        'extension': ext,
                        'attachment_id': att_id,
                        'size': size,
                    })

            # Recurse into nested parts
            if 'parts' in part:
                attachments.extend(get_attachments_info(part))

    return attachments


def download_attachment(service, msg_id: str, att_id: str) -> bytes:
    """Download an attachment by message and attachment ID."""
    result = service.users().messages().attachments().get(
        userId='me', messageId=msg_id, id=att_id
    ).execute()
    data = result.get('data', '')
    return base64.urlsafe_b64decode(data)


def get_header(headers: list, name: str) -> str:
    """Get a specific header value from message headers."""
    for header in headers:
        if header['name'].lower() == name.lower():
            return header['value']
    return ''


def main():
    print("=" * 60)
    print("Gmail Audio Import Script")
    print(f"Target: {TARGET_ACCOUNT}")
    print(f"Label:  {LABEL_NAME}")
    print(f"Output: {OUTPUT_DIR}")
    print("=" * 60)

    # Authenticate
    service = authenticate()

    # Find label
    print(f"\n🔍 Looking for label '{LABEL_NAME}'...")
    label_id = find_label_id(service, LABEL_NAME)
    print(f"✅ Found label: {label_id}")

    # Get messages in label
    print(f"\n📧 Fetching emails from '{LABEL_NAME}'...")
    messages = []
    page_token = None

    while True:
        kwargs = {
            'userId': 'me',
            'labelIds': [label_id],
            'maxResults': 100,
        }
        if page_token:
            kwargs['pageToken'] = page_token

        results = service.users().messages().list(**kwargs).execute()
        batch = results.get('messages', [])
        messages.extend(batch)

        page_token = results.get('nextPageToken')
        if not page_token:
            break

    print(f"✅ Found {len(messages)} email(s)")

    if not messages:
        print("No emails found. Nothing to do.")
        return

    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Process each email
    imported_files = []
    skipped_files = []

    for i, msg_info in enumerate(messages, 1):
        msg_id = msg_info['id']
        msg = service.users().messages().get(
            userId='me', id=msg_id, format='full'
        ).execute()

        headers = msg.get('payload', {}).get('headers', [])
        subject = get_header(headers, 'Subject') or '(no subject)'
        from_addr = get_header(headers, 'From')
        date_str = get_header(headers, 'Date')

        print(f"\n--- Email {i}/{len(messages)} ---")
        print(f"  Subject: {subject}")
        print(f"  From:    {from_addr}")
        print(f"  Date:    {date_str}")

        # Get body text
        body = get_email_body(msg['payload'])

        # Get audio attachments
        attachments = get_attachments_info(msg['payload'])

        if not attachments:
            print(f"  ⚠️  No audio attachments found, skipping.")
            continue

        print(f"  📎 {len(attachments)} audio file(s)")

        for att in attachments:
            filename = att['filename']
            safe_name = sanitize_filename(Path(filename).stem)
            ext = att['extension']
            full_name = f"{safe_name}{ext}"
            audio_path = OUTPUT_DIR / full_name
            notes_path = OUTPUT_DIR / f"{safe_name}.md"

            # Skip if already downloaded
            if audio_path.exists():
                print(f"  ⏭️  {full_name} already exists, skipping.")
                skipped_files.append(full_name)
                continue

            # Download audio
            print(f"  ⬇️  Downloading {full_name} ({att['size'] / 1024:.1f} KB)...")
            audio_data = download_attachment(service, msg_id, att['attachment_id'])

            with open(audio_path, 'wb') as f:
                f.write(audio_data)

            # Save notes as .md
            note_content = f"# {safe_name}\n\n"
            note_content += f"**Source Email:** {subject}\n"
            note_content += f"**From:** {from_addr}\n"
            note_content += f"**Date:** {date_str}\n"
            note_content += f"**Original Filename:** {filename}\n"
            note_content += f"**File Size:** {len(audio_data) / 1024:.1f} KB\n\n"

            if body:
                note_content += f"## Notes\n\n{body}\n"
            else:
                note_content += "## Notes\n\n*(No text in email body)*\n"

            with open(notes_path, 'w', encoding='utf-8') as f:
                f.write(note_content)

            print(f"  ✅ Saved: {full_name} + {safe_name}.md")

            imported_files.append({
                'audio': full_name,
                'notes': f"{safe_name}.md",
                'subject': subject,
                'size_kb': len(audio_data) / 1024,
            })

    # Generate import manifest
    manifest_path = OUTPUT_DIR / '_import_manifest.md'
    manifest = f"# Gmail Audio Import Manifest\n\n"
    manifest += f"**Account:** {TARGET_ACCOUNT}\n"
    manifest += f"**Label:** {LABEL_NAME}\n"
    manifest += f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
    manifest += f"**Emails processed:** {len(messages)}\n"
    manifest += f"**Files imported:** {len(imported_files)}\n"
    manifest += f"**Files skipped:** {len(skipped_files)}\n\n"

    if imported_files:
        manifest += "## Imported Files\n\n"
        manifest += "| Audio File | Notes | Source Email | Size |\n"
        manifest += "|-----------|-------|-------------|------|\n"
        for f in imported_files:
            manifest += f"| {f['audio']} | {f['notes']} | {f['subject']} | {f['size_kb']:.1f} KB |\n"
        manifest += "\n"

    if skipped_files:
        manifest += "## Skipped Files (already exist)\n\n"
        for f in skipped_files:
            manifest += f"- {f}\n"

    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(manifest)

    # Summary
    print(f"\n{'=' * 60}")
    print(f"✅ Import complete!")
    print(f"   Imported: {len(imported_files)} file(s)")
    print(f"   Skipped:  {len(skipped_files)} file(s)")
    print(f"   Output:   {OUTPUT_DIR}")
    print(f"   Manifest: {manifest_path}")
    print(f"{'=' * 60}")


if __name__ == '__main__':
    main()
