import sys, io, os

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

PACKAGE_NAME = "com.neo3151.huntingcalls"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
SCRIPT_DIR = r"c:\Users\neo31\Hunting_Call\scripts"
TOKEN_FILE = os.path.join(SCRIPT_DIR, "play_token.json")

def get_credentials():
    creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds.valid and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    return creds

def assign():
    creds = get_credentials()
    import httplib2, google_auth_httplib2
    http = httplib2.Http(timeout=600)
    authed_http = google_auth_httplib2.AuthorizedHttp(creds, http=http)
    service = build("androidpublisher", "v3", http=authed_http)

    print("📝 Creating edit...")
    edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit["id"]
    
    print("🚀 Assigning version 102 to beta track as DRAFT...")
    release_body = {
        "track": "beta",
        "releases": [
            {
                "name": "v2.1.0 Beta",
                "versionCodes": ["102"],
                "status": "draft",
                "releaseNotes": [{"language": "en-US", "text": "Latest open beta release adding performance improvements and bug fixes for the upcoming public release. Please report any bugs you encounter."}],
            }
        ],
    }
    
    service.edits().tracks().update(
        packageName=PACKAGE_NAME, editId=edit_id, track="beta", body=release_body
    ).execute()
    
    print("💾 Committing edit...")
    service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print("🎉 Done! v102 is now safely assigned as a DRAFT in the beta track.")

try:
    assign()
except Exception as e:
    print(f"Error: {e}")
