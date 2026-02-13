"""
Capture ALL emails from the Animal Sounds Gmail label, including
the ones without audio attachments (YouTube links, text-only).
Saves a comprehensive .md with every email's full content.
"""
import os, base64, json, sys
from pathlib import Path
from datetime import datetime
from html.parser import HTMLParser

# Gmail API
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCRIPT_DIR = Path(__file__).parent
TOKEN_FILE = SCRIPT_DIR / 'gmail_token.json'
CREDENTIALS_FILE = SCRIPT_DIR / 'credentials.json'
OUTPUT_DIR = SCRIPT_DIR.parent / 'assets' / 'audio' / 'gmail_imports'
LABEL_NAME = "Animal Sounds"

SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']


class HTMLTextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self._text = []
        self._skip = False

    def handle_starttag(self, tag, attrs):
        if tag in ('style', 'script'):
            self._skip = True
        if tag in ('br', 'p', 'div', 'tr', 'li'):
            self._text.append('\n')

    def handle_endtag(self, tag):
        if tag in ('style', 'script'):
            self._skip = False

    def handle_data(self, data):
        if not self._skip:
            self._text.append(data)

    def get_text(self):
        return ''.join(self._text).strip()


def html_to_text(html_content):
    parser = HTMLTextExtractor()
    parser.feed(html_content)
    return parser.get_text()


def get_email_body(payload):
    """Extract email body text from message payload."""
    body_text = ""
    
    if 'parts' in payload:
        for part in payload['parts']:
            mime = part.get('mimeType', '')
            if mime == 'text/plain':
                data = part.get('body', {}).get('data', '')
                if data:
                    body_text = base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')
                    break
            elif mime == 'text/html':
                data = part.get('body', {}).get('data', '')
                if data:
                    html = base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')
                    body_text = html_to_text(html)
            elif mime.startswith('multipart/'):
                body_text = get_email_body(part)
                if body_text:
                    break
    else:
        mime = payload.get('mimeType', '')
        data = payload.get('body', {}).get('data', '')
        if data:
            decoded = base64.urlsafe_b64decode(data).decode('utf-8', errors='replace')
            if mime == 'text/html':
                body_text = html_to_text(decoded)
            else:
                body_text = decoded

    return body_text.strip()


def get_header(headers, name):
    for h in headers:
        if h['name'].lower() == name.lower():
            return h['value']
    return ''


def get_attachments_info(payload):
    """Get list of attachment filenames from message payload."""
    attachments = []
    audio_exts = {'.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac', '.wma'}

    def _scan(part):
        fn = part.get('filename', '')
        if fn:
            ext = os.path.splitext(fn)[1].lower()
            if ext in audio_exts:
                attachments.append(fn)
        if 'parts' in part:
            for p in part['parts']:
                _scan(p)

    _scan(payload)
    return attachments


def main():
    print("=" * 60)
    print("FULL GMAIL EMAIL CAPTURE - Animal Sounds")
    print("=" * 60)

    # Authenticate
    creds = None
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("Refreshing token...")
            creds.refresh(Request())
            with open(TOKEN_FILE, 'w') as f:
                f.write(creds.to_json())
        else:
            print("ERROR: No valid token. Run gmail_audio_import.py first.")
            sys.exit(1)

    service = build('gmail', 'v1', credentials=creds)

    # Find label
    results = service.users().labels().list(userId='me').execute()
    label_id = None
    for label in results.get('labels', []):
        if label['name'].lower() == LABEL_NAME.lower():
            label_id = label['id']
            break
    
    if not label_id:
        print(f"ERROR: Label '{LABEL_NAME}' not found")
        sys.exit(1)

    # Fetch all messages
    messages = []
    page_token = None
    while True:
        kwargs = {'userId': 'me', 'labelIds': [label_id], 'maxResults': 100}
        if page_token:
            kwargs['pageToken'] = page_token
        results = service.users().messages().list(**kwargs).execute()
        messages.extend(results.get('messages', []))
        page_token = results.get('nextPageToken')
        if not page_token:
            break

    print(f"Found {len(messages)} email(s)")

    # Process each email
    all_emails = []
    for i, msg_info in enumerate(messages, 1):
        msg = service.users().messages().get(
            userId='me', id=msg_info['id'], format='full'
        ).execute()

        headers = msg.get('payload', {}).get('headers', [])
        subject = get_header(headers, 'Subject') or '(no subject)'
        from_addr = get_header(headers, 'From')
        date_str = get_header(headers, 'Date')
        to_addr = get_header(headers, 'To')

        body = get_email_body(msg['payload'])
        attachments = get_attachments_info(msg['payload'])

        email_data = {
            'num': i,
            'subject': subject,
            'from': from_addr,
            'to': to_addr,
            'date': date_str,
            'body': body,
            'attachments': attachments,
            'has_audio': len(attachments) > 0,
        }
        all_emails.append(email_data)
        print(f"  [{i}/{len(messages)}] {subject[:60]}")

    # Build comprehensive .md file
    md = "# Animal Sounds - Gmail Email Archive\n\n"
    md += f"**Account:** benchmarkappsllc@gmail.com\n"
    md += f"**Label:** {LABEL_NAME}\n"
    md += f"**Captured:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
    md += f"**Total Emails:** {len(all_emails)}\n"
    md += f"**With Audio Attachments:** {sum(1 for e in all_emails if e['has_audio'])}\n"
    md += f"**YouTube Links / Text Only:** {sum(1 for e in all_emails if not e['has_audio'])}\n\n"
    md += "---\n\n"

    # Section 1: Emails with audio attachments
    audio_emails = [e for e in all_emails if e['has_audio']]
    if audio_emails:
        md += "## Emails with Audio Attachments\n\n"
        for e in audio_emails:
            md += f"### {e['subject']}\n\n"
            md += f"- **From:** {e['from']}\n"
            md += f"- **Date:** {e['date']}\n"
            if e['attachments']:
                md += f"- **Attachments:** {', '.join(e['attachments'])}\n"
            md += f"\n"
            if e['body']:
                md += f"> {e['body']}\n\n"
            else:
                md += "> *(No text in email body)*\n\n"
            md += "---\n\n"

    # Section 2: YouTube links and text-only emails
    text_emails = [e for e in all_emails if not e['has_audio']]
    if text_emails:
        md += "## YouTube Links & Reference Emails\n\n"
        for e in text_emails:
            md += f"### {e['subject']}\n\n"
            md += f"- **From:** {e['from']}\n"
            md += f"- **Date:** {e['date']}\n\n"
            if e['body']:
                # Truncate very long bodies but keep URLs
                body_lines = e['body'].split('\n')
                # Keep first 30 lines to avoid bloat
                trimmed = '\n'.join(body_lines[:30])
                if len(body_lines) > 30:
                    trimmed += f"\n\n*(... {len(body_lines) - 30} more lines)*"
                md += f"{trimmed}\n\n"
            else:
                md += "*(No text in email body)*\n\n"
            md += "---\n\n"

    # Write output
    output_path = OUTPUT_DIR / '_all_emails.md'
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(md)
    
    print(f"\nSaved comprehensive archive to: {output_path}")
    print(f"  {len(audio_emails)} emails with audio")
    print(f"  {len(text_emails)} YouTube/text emails")


if __name__ == "__main__":
    main()
