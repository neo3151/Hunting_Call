"""Convert walkthrough.md to PDF using fpdf2 with Unicode font and email via Gmail."""
import os, base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from fpdf import FPDF

WALKTHROUGH = r"C:\Users\neo31\.gemini\antigravity\brain\2b39fd71-fd88-4cd3-b41a-164936a82bfd\walkthrough.md"
PDF = r"C:\Users\neo31\Hunting_Call\scripts\complete_sound_library.pdf"
TOKEN = r"C:\Users\neo31\Hunting_Call\scripts\token.json"
SCOPES = [
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
]


def main():
    with open(WALKTHROUGH, "r", encoding="utf-8") as f:
        lines = f.readlines()

    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=20)

    # Add Unicode font (Arial TTF from Windows)
    pdf.add_font("ArialUni", "", r"C:\Windows\Fonts\arial.ttf", uni=True)
    pdf.add_font("ArialUni", "B", r"C:\Windows\Fonts\arialbd.ttf", uni=True)
    pdf.add_font("ArialUni", "I", r"C:\Windows\Fonts\ariali.ttf", uni=True)
    pdf.add_font("ArialUni", "BI", r"C:\Windows\Fonts\arialbi.ttf", uni=True)

    pdf.add_page()

    for line in lines:
        line = line.rstrip()

        if line.startswith("# "):
            pdf.set_font("ArialUni", "B", 16)
            pdf.cell(0, 10, line[2:], new_x="LMARGIN", new_y="NEXT")
            pdf.set_draw_color(26, 94, 26)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(3)

        elif line.startswith("## "):
            pdf.ln(3)
            pdf.set_font("ArialUni", "B", 13)
            pdf.set_text_color(45, 125, 45)
            pdf.cell(0, 8, line[3:], new_x="LMARGIN", new_y="NEXT")
            pdf.set_text_color(0, 0, 0)
            pdf.ln(2)

        elif line.startswith("### "):
            pdf.ln(2)
            pdf.set_font("ArialUni", "B", 10)
            pdf.set_text_color(68, 68, 68)
            pdf.cell(0, 7, line[4:], new_x="LMARGIN", new_y="NEXT")
            pdf.set_text_color(0, 0, 0)
            pdf.ln(1)

        elif line.startswith("|") and "---" not in line:
            cells = [c.strip() for c in line.strip("|").split("|")]
            is_header = any(
                c in ["Call Type", "Diff", "Duration", "Pitch", "Audio File",
                       "Difficulty", "Category", "Count"]
                for c in cells
            )
            if is_header:
                pdf.set_font("ArialUni", "B", 7)
                pdf.set_fill_color(26, 94, 26)
                pdf.set_text_color(255, 255, 255)
            else:
                pdf.set_font("ArialUni", "", 7)
                pdf.set_text_color(34, 34, 34)
                pdf.set_fill_color(255, 255, 255)

            w = 190 // max(len(cells), 1)
            for c in cells:
                pdf.cell(w, 5, c[:45], border=1, fill=True)
            pdf.ln()
            pdf.set_text_color(0, 0, 0)

        elif line.startswith("|") and "---" in line:
            pass

        elif line.startswith(">"):
            text = line.lstrip("> ")
            pdf.set_font("ArialUni", "I", 7.5)
            pdf.set_text_color(80, 80, 80)
            pdf.multi_cell(180, 4, text)
            pdf.ln(1)
            pdf.set_text_color(0, 0, 0)

        elif line.startswith("---"):
            pdf.ln(2)
            pdf.set_draw_color(200, 200, 200)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(2)

        elif line.startswith("**"):
            text = line.replace("**", "")
            pdf.set_font("ArialUni", "B", 9)
            pdf.cell(0, 6, text, new_x="LMARGIN", new_y="NEXT")

        elif line.strip():
            pdf.set_font("ArialUni", "", 8)
            pdf.multi_cell(0, 4, line)

    pdf.output(PDF)
    sz = os.path.getsize(PDF)
    print(f"PDF created: {sz // 1024} KB")

    # Send email
    creds = Credentials.from_authorized_user_file(TOKEN, SCOPES)
    if not creds.valid and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    service = build("gmail", "v1", credentials=creds)

    msg = MIMEMultipart()
    msg["to"] = "benchmarkappsllc@gmail.com"
    msg["from"] = "benchmarkappsllc@gmail.com"
    msg["subject"] = "Your OUTCALL PDF Collection"
    msg.attach(MIMEText(
        "To: neo@example.com\n\n"
        "Attached: Complete Sound Library for OUTCALL\n"
        "76 calls across 4 categories (Waterfowl, Big Game, Predators, Land Birds)"
    ))

    with open(PDF, "rb") as f:
        att = MIMEApplication(f.read(), _subtype="pdf")
        att.add_header(
            "Content-Disposition", "attachment",
            filename="Complete_Sound_Library.pdf"
        )
        msg.attach(att)

    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    result = service.users().messages().send(
        userId="me", body={"raw": raw}
    ).execute()
    print(f"Email sent with PDF! ID: {result['id']}")


if __name__ == "__main__":
    main()
