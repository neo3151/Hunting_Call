#!/usr/bin/env python3
"""
Upload an AAB to Google Play Console via the Android Publisher API.

Usage:
  python scripts/upload_play.py --track internal --aab build/app/outputs/bundle/release/app-release.aab
  python scripts/upload_play.py --track alpha --aab build/app/outputs/bundle/release/app-release.aab --notes "Release notes here"
  python scripts/upload_play.py --track production --aab build/app/outputs/bundle/release/app-release.aab

First run will open a browser for OAuth2 consent. Token is cached in scripts/play_token.json.
"""

import argparse
import os
import sys
import io

# Fix Windows console encoding for emoji/unicode
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PACKAGE_NAME = "com.neo3151.huntingcalls"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CREDENTIALS_FILE = os.path.join(PROJECT_DIR, "credentials.json")
TOKEN_FILE = os.path.join(SCRIPT_DIR, "play_token.json")


def get_credentials():
    """Get or refresh OAuth2 credentials."""
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("🔄 Refreshing token...")
            creds.refresh(Request())
        else:
            print("🔐 Opening browser for OAuth2 consent...")
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)

        with open(TOKEN_FILE, "w") as f:
            f.write(creds.to_json())
        print(f"✅ Token saved to {TOKEN_FILE}")

    return creds


def upload_aab(track: str, aab_path: str, release_name: str, notes: str):
    """Upload AAB to the specified track."""
    if not os.path.exists(aab_path):
        print(f"❌ AAB not found: {aab_path}")
        sys.exit(1)

    size_mb = os.path.getsize(aab_path) / (1024 * 1024)
    print(f"📦 AAB: {aab_path} ({size_mb:.1f} MB)")
    print(f"🎯 Track: {track}")
    print(f"📝 Release: {release_name}")
    print()

    creds = get_credentials()
    service = build("androidpublisher", "v3", credentials=creds)

    # 1. Create an edit
    print("📝 Creating edit...")
    edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit["id"]
    print(f"   Edit ID: {edit_id}")

    # 2. Upload the AAB
    print("⬆️  Uploading AAB (this may take a few minutes)...")
    media = MediaFileUpload(aab_path, mimetype="application/octet-stream", resumable=True)
    bundle = service.edits().bundles().upload(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        media_body=media,
    ).execute()
    version_code = bundle["versionCode"]
    print(f"   ✅ Uploaded! Version code: {version_code}")

    # 3. Assign to track with release notes
    print(f"🚀 Assigning to {track} track...")
    release_body = {
        "track": track,
        "releases": [
            {
                "name": release_name,
                "versionCodes": [str(version_code)],
                "status": "completed",
                "releaseNotes": [
                    {"language": "en-US", "text": notes}
                ],
            }
        ],
    }
    service.edits().tracks().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        track=track,
        body=release_body,
    ).execute()
    print(f"   ✅ Assigned to {track}")

    # 4. Commit the edit
    print("💾 Committing edit...")
    service.edits().commit(
        packageName=PACKAGE_NAME,
        editId=edit_id,
    ).execute()
    print(f"\n🎉 Done! v{version_code} is now live on the {track} track.")


def main():
    parser = argparse.ArgumentParser(description="Upload AAB to Google Play Console")
    parser.add_argument("--track", required=True, choices=["internal", "alpha", "beta", "production"],
                        help="Release track")
    parser.add_argument("--aab", required=True, help="Path to the AAB file")
    parser.add_argument("--name", default="", help="Release name (e.g. 'Improved Beta')")
    parser.add_argument("--notes", default="Bug fixes and improvements.", help="Release notes (max 500 chars)")
    args = parser.parse_args()

    if len(args.notes) > 500:
        print(f"⚠️  Release notes are {len(args.notes)} chars, trimming to 500")
        args.notes = args.notes[:500]

    upload_aab(
        track=args.track,
        aab_path=args.aab,
        release_name=args.name or f"v{args.track}",
        notes=args.notes,
    )


if __name__ == "__main__":
    main()
