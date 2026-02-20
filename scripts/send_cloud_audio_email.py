"""Send the cloud audio strategy email via Gmail API."""
import os, base64
from email.mime.text import MIMEText
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPES = [
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
]


def main():
    # Read the cloud audio strategy file
    strategy_path = os.path.expanduser("~/.gemini/Outcall_CloudAudio.md")
    with open(strategy_path, "r") as f:
        body = f.read()

    script_dir = os.path.dirname(__file__)
    token_path = os.path.join(script_dir, "token.json")
    creds_path = os.path.join(script_dir, "credentials.json")
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

    msg = MIMEText(body)
    msg["to"] = "benchmarkappsllc@gmail.com"
    msg["from"] = "benchmarkappsllc@gmail.com"
    msg["subject"] = "this is interesting"

    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    result = service.users().messages().send(userId="me", body={"raw": raw}).execute()
    print(f"Email sent! Message ID: {result['id']}")


if __name__ == "__main__":
    main()
