#!/usr/bin/env python3
"""Upload or promote an AAB to a Google Play Store track via CLI.

Usage:
    # Upload a new AAB to internal testing
    python3 scripts/upload_to_play_store.py

    # Upload to a specific track
    python3 scripts/upload_to_play_store.py --track beta

    # Promote an already-uploaded version to a different track
    python3 scripts/upload_to_play_store.py --promote --version-code 8 --track beta

Requirements:
    pip3 install google-api-python-client google-auth google-auth-httplib2
"""

import argparse
import sys
import socket
from pathlib import Path
socket.setdefaulttimeout(300)

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# --- Configuration ---
PACKAGE_NAME = "com.neo3151.huntingcalls"
SCRIPT_DIR = Path(__file__).parent
DEFAULT_KEY_PATH = SCRIPT_DIR / "play-store-key.json"
DEFAULT_AAB_PATH = (
    SCRIPT_DIR.parent / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
)
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def get_service(key_path: Path):
    """Authenticate and return the Play Developer API service."""
    credentials = service_account.Credentials.from_service_account_file(
        str(key_path), scopes=SCOPES
    )
    return build("androidpublisher", "v3", credentials=credentials)


def promote_to_track(service, version_code: int, track: str, release_name: str = "", notes: str = ""):
    """Promote an already-uploaded version code to a track."""
    print(f"📦 Package:      {PACKAGE_NAME}")
    print(f"🔢 Version code: {version_code}")
    print(f"🎯 Track:        {track}")
    if release_name:
        print(f"🏷️  Release:      {release_name}")
    print()

    # 1. Create a new edit
    print("Creating edit...")
    edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit["id"]
    print(f"  Edit ID: {edit_id}")

    # 2. Assign to track
    print(f"Assigning version {version_code} to '{track}' track...")
    release = {
        "versionCodes": [str(version_code)],
        "status": "completed",
    }
    if release_name:
        release["name"] = release_name
    if notes:
        release["releaseNotes"] = [{"language": "en-US", "text": notes}]

    track_body = {"track": track, "releases": [release]}
    service.edits().tracks().update(
        packageName=PACKAGE_NAME, editId=edit_id, track=track, body=track_body
    ).execute()
    print(f"  ✅ Assigned to {track}")

    # 3. Commit the edit
    print("Committing edit...")
    service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print("  ✅ Edit committed!")

    print()
    print(f"🎉 Done! Version {version_code} promoted to '{track}'.")
    print(f"   Check status: https://play.google.com/console")


def upload_aab(service, aab_path: Path, track: str, release_name: str = "", notes: str = ""):
    """Upload AAB to the specified track."""
    print(f"📦 Package:  {PACKAGE_NAME}")
    print(f"📁 AAB:      {aab_path} ({aab_path.stat().st_size / 1024 / 1024:.1f} MB)")
    print(f"🎯 Track:    {track}")
    if release_name:
        print(f"🏷️  Release:  {release_name}")
    if notes:
        print(f"📝 Notes:    {notes[:80]}{'...' if len(notes) > 80 else ''}")
    print()

    # 1. Create a new edit
    print("Creating edit...")
    edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit["id"]
    print(f"  Edit ID: {edit_id}")

    # 2. Upload the AAB
    print("Uploading AAB (this may take a minute)...")
    media = MediaFileUpload(str(aab_path), mimetype="application/octet-stream", resumable=True)
    upload_request = service.edits().bundles().upload(
        packageName=PACKAGE_NAME, editId=edit_id, media_body=media
    )

    response = None
    while response is None:
        status, response = upload_request.next_chunk()
        if status:
            pct = int(status.progress() * 100)
            print(f"  Upload progress: {pct}%")

    version_code = response["versionCode"]
    print(f"  ✅ Uploaded! Version code: {version_code}")

    # 3. Assign to track with release name and notes
    print(f"Assigning to '{track}' track...")
    release = {
        "versionCodes": [str(version_code)],
        "status": "completed",
    }
    if release_name:
        release["name"] = release_name
    if notes:
        release["releaseNotes"] = [{"language": "en-US", "text": notes}]

    track_body = {"track": track, "releases": [release]}
    service.edits().tracks().update(
        packageName=PACKAGE_NAME, editId=edit_id, track=track, body=track_body
    ).execute()
    print(f"  ✅ Assigned to {track}")

    # 4. Commit the edit
    print("Committing edit...")
    service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print("  ✅ Edit committed!")

    print()
    print("🎉 Done! Your AAB has been uploaded to the Play Store.")
    print(f"   Track: {track}")
    print(f"   Version code: {version_code}")
    if release_name:
        print(f"   Release: {release_name}")
    print(f"   Check status: https://play.google.com/console")


def main():
    parser = argparse.ArgumentParser(description="Upload or promote AAB on Google Play Store")
    parser.add_argument(
        "--track",
        default="alpha",
        choices=["internal", "alpha", "beta", "production"],
        help="Release track (default: alpha)",
    )
    parser.add_argument(
        "--aab",
        type=Path,
        default=DEFAULT_AAB_PATH,
        help=f"Path to AAB file (default: {DEFAULT_AAB_PATH})",
    )
    parser.add_argument(
        "--key",
        type=Path,
        default=DEFAULT_KEY_PATH,
        help=f"Path to service account JSON key (default: {DEFAULT_KEY_PATH})",
    )
    parser.add_argument(
        "--name",
        default="",
        help="Release name (e.g. 'v1.8.3 — Smart Library')",
    )
    parser.add_argument(
        "--notes",
        default="Bug fixes and improvements.",
        help="Release notes (max 500 chars)",
    )
    parser.add_argument(
        "--promote",
        action="store_true",
        help="Promote an existing version to a track (no upload)",
    )
    parser.add_argument(
        "--version-code",
        type=int,
        help="Version code to promote (required with --promote)",
    )
    args = parser.parse_args()

    if len(args.notes) > 500:
        print(f"⚠️  Release notes are {len(args.notes)} chars, trimming to 500")
        args.notes = args.notes[:500]

    # Validate inputs
    if not args.key.exists():
        print(f"❌ Service account key not found: {args.key}")
        print("   Download it from Google Cloud Console → IAM → Service Accounts → Keys")
        sys.exit(1)

    service = get_service(args.key)

    if args.promote:
        if not args.version_code:
            print("❌ --version-code is required when using --promote")
            sys.exit(1)
        promote_to_track(service, args.version_code, args.track, args.name, args.notes)
    else:
        if not args.aab.exists():
            print(f"❌ AAB file not found: {args.aab}")
            print("   Run: ./scripts/build_app.sh")
            sys.exit(1)
        upload_aab(service, args.aab, args.track, args.name, args.notes)


if __name__ == "__main__":
    main()

