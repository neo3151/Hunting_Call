#!/usr/bin/env python3
"""
Send a markdown file as a formatted HTML email via Gmail API.

Usage:
  python3 scripts/send_markdown_email.py <to> <subject> <markdown_file>

Uses existing OAuth credentials from scripts/token.json.
"""

import sys, os, base64, re
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPES = [
    "https://www.googleapis.com/auth/gmail.send",
]
SENDER = "benchmarkappsllc@gmail.com"


def get_gmail_service():
    script_dir = os.path.dirname(__file__)
    token_path = os.path.join(script_dir, "gmail_token.json")
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
            from google_auth_oauthlib.flow import InstalledAppFlow
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
            with open(token_path, "w") as f:
                f.write(creds.to_json())

    return build("gmail", "v1", credentials=creds)


def inline_format(text):
    text = text.replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong style="color:#cdd6f4;">\1</strong>', text)
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    text = re.sub(r'`(.+?)`', r'<code style="background:#313244;color:#f38ba8;padding:2px 6px;border-radius:4px;font-size:13px;">\1</code>', text)
    return text


def markdown_to_html(md_text):
    lines = md_text.split("\n")
    html = []
    in_table = False
    in_code = False
    in_list = False

    for line in lines:
        s = line.strip()

        if s.startswith("```"):
            if in_code:
                html.append("</code></pre>")
            else:
                html.append('<pre style="background:#1e1e2e;color:#cdd6f4;padding:16px;border-radius:8px;font-size:13px;"><code>')
            in_code = not in_code
            continue

        if in_code:
            html.append(line.replace("<", "&lt;").replace(">", "&gt;"))
            continue

        if s == "---":
            html.append('<hr style="border:none;border-top:1px solid #444;margin:24px 0;">')
            continue

        if s.startswith("# "):
            html.append(f'<h1 style="color:#cdd6f4;font-family:sans-serif;border-bottom:2px solid #89b4fa;padding-bottom:8px;">{s[2:]}</h1>')
            continue
        if s.startswith("## "):
            html.append(f'<h2 style="color:#a6adc8;font-family:sans-serif;margin-top:24px;">{s[3:]}</h2>')
            continue
        if s.startswith("### "):
            html.append(f'<h3 style="color:#89b4fa;font-family:sans-serif;">{s[4:]}</h3>')
            continue

        if "|" in s and s.startswith("|"):
            cells = [c.strip() for c in s.split("|")[1:-1]]
            if all(re.match(r'^[-:]+$', c) for c in cells):
                continue
            if not in_table:
                html.append('<table style="width:100%;border-collapse:collapse;margin:16px 0;font-family:sans-serif;font-size:14px;">')
                html.append("<tr>")
                for cell in cells:
                    html.append(f'<th style="background:#313244;color:#cdd6f4;padding:10px 14px;text-align:left;border:1px solid #45475a;">{inline_format(cell)}</th>')
                html.append("</tr>")
                in_table = True
            else:
                html.append("<tr>")
                for cell in cells:
                    html.append(f'<td style="padding:10px 14px;color:#bac2de;border:1px solid #45475a;">{inline_format(cell)}</td>')
                html.append("</tr>")
            continue
        elif in_table:
            html.append("</table>")
            in_table = False

        if s.startswith("- [ ] "):
            if not in_list:
                html.append('<ul style="list-style:none;padding-left:8px;">')
                in_list = True
            html.append(f'<li style="color:#bac2de;font-family:sans-serif;padding:3px 0;">☐ {inline_format(s[6:])}</li>')
            continue
        if s.startswith("- [x] "):
            if not in_list:
                html.append('<ul style="list-style:none;padding-left:8px;">')
                in_list = True
            html.append(f'<li style="color:#a6e3a1;font-family:sans-serif;padding:3px 0;">✅ {inline_format(s[6:])}</li>')
            continue
        if s.startswith("- "):
            if not in_list:
                html.append('<ul style="padding-left:20px;">')
                in_list = True
            html.append(f'<li style="color:#bac2de;font-family:sans-serif;padding:3px 0;">{inline_format(s[2:])}</li>')
            continue
        elif in_list:
            html.append("</ul>")
            in_list = False

        if not s:
            html.append("<br>")
            continue

        html.append(f'<p style="color:#bac2de;font-family:sans-serif;font-size:14px;line-height:1.6;margin:8px 0;">{inline_format(s)}</p>')

    if in_table: html.append("</table>")
    if in_list: html.append("</ul>")

    body = "\n".join(html)
    return f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"></head>
<body style="background:#1e1e2e;padding:32px;margin:0;">
  <div style="max-width:700px;margin:0 auto;background:#181825;border-radius:12px;padding:32px;border:1px solid #313244;">
    {body}
    <p style="color:#585b70;font-family:sans-serif;font-size:11px;text-align:center;margin-top:32px;border-top:1px solid #313244;padding-top:16px;">
      Sent from Hunting Call Dev Environment
    </p>
  </div>
</body></html>"""


def send_email(to_addr, subject, md_file):
    md_text = Path(md_file).read_text()
    html_body = markdown_to_html(md_text)

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = SENDER
    msg["To"] = to_addr
    msg.attach(MIMEText(md_text, "plain"))
    msg.attach(MIMEText(html_body, "html"))

    service = get_gmail_service()
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    result = service.users().messages().send(userId="me", body={"raw": raw}).execute()
    print(f"✅ Email sent to {to_addr}")
    print(f"   Subject: {subject}")
    print(f"   Message ID: {result['id']}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <to_email> <subject> <markdown_file>")
        sys.exit(1)
    send_email(sys.argv[1], sys.argv[2], sys.argv[3])
