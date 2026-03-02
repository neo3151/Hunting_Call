"""Send the beta testing guide email via Gmail API."""
import os, base64
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
import markdown

SCOPES = [
    "https://mail.google.com/",
]

def main():
    script_dir = os.path.dirname(__file__)
    token_path = os.path.expanduser("~/Downloads/windows_migration/gmail_token.json")
    creds_path = os.path.expanduser("~/Downloads/windows_migration/credentials.json")
    md_path = os.path.join(script_dir, "..", "docs", "BETA_TESTING.md")
    
    with open(md_path, "r", encoding="utf-8") as f:
        md_content = f.read()
    
    html_content = markdown.markdown(md_content)

    creds = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(token_path, "w") as f:
                f.write(creds.to_json())
        else:
            from google_auth_oauthlib.flow import InstalledAppFlow
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
            with open(token_path, "w") as f:
                f.write(creds.to_json())

    service = build("gmail", "v1", credentials=creds)

    msg = MIMEMultipart("alternative")
    msg["to"] = "arivers199292@gmail.com"
    msg["from"] = "benchmarkappsllc@gmail.com"
    msg["subject"] = "Outcall: Closed Beta Testing Instructions"

    part1 = MIMEText(md_content, "plain")
    part2 = MIMEText(f"<html><body>{html_content}</body></html>", "html")
    
    msg.attach(part1)
    msg.attach(part2)

    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    result = service.users().messages().send(userId="me", body={"raw": raw}).execute()
    print(f"Beta Email sent to arivers199292@gmail.com! Message ID: {result['id']}")

if __name__ == "__main__":
    main()
