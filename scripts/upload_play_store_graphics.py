#!/usr/bin/env python3
"""Upload store listing graphics (icon, feature graphic, screenshots) to Google Play."""
import argparse
import sys
from pathlib import Path
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# --- Configuration ---
PACKAGE_NAME = "com.neo3151.huntingcalls" # Verified from upload_to_play_store.py
SCRIPT_DIR = Path(__file__).parent
DEFAULT_KEY_PATH = SCRIPT_DIR / "play-store-key.json"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

def get_service(key_path: Path):
    credentials = service_account.Credentials.from_service_account_file(
        str(key_path), scopes=SCOPES
    )
    return build("androidpublisher", "v3", credentials=credentials)

def upload_images(service, edit_id, image_type, file_paths):
    """Upload one or more images of a specific type."""
    print(f"🖼️ Uploading {image_type}...")
    
    # First, clear existing images of this type (optional, but cleaner for screenshots)
    if image_type == 'phoneScreenshots':
        service.edits().images().deleteall(
            packageName=PACKAGE_NAME, editId=edit_id, imageType=image_type, language='en-US'
        ).execute()

    for path in file_paths:
        print(f"  Uploading {path.name}...")
        media = MediaFileUpload(str(path), mimetype="image/png")
        service.edits().images().upload(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            imageType=image_type,
            language='en-US',
            media_body=media
        ).execute()
        print(f"    ✅ Done.")

def update_listing(service, edit_id):
    """Update textual listing metadata if needed."""
    print("📝 Updating store listing metadata (OUTCALL)...")
    listing_body = {
        "title": "OUTCALL",
        "shortDescription": "The ultimate hunting call training app.",
        "fullDescription": "Master your hunting calls with OUTCALL. Real-time analysis, professional reference calls, and daily challenges to sharpen your skills in the field."
    }
    service.edits().listings().update(
        packageName=PACKAGE_NAME, editId=edit_id, language='en-US', body=listing_body
    ).execute()
    print("  ✅ Listing updated.")

def main():
    parser = argparse.ArgumentParser(description="Upload graphics to Google Play Console")
    parser.add_argument("--key", type=Path, default=DEFAULT_KEY_PATH)
    args = parser.parse_args()

    if not args.key.exists():
        print(f"❌ Key not found: {args.key}")
        sys.exit(1)

    service = get_service(args.key)
    base_dir = SCRIPT_DIR.parent
    
    # Define asset paths
    icon_path = base_dir / "assets" / "play_store" / "icon_512.png"
    feature_graphic_path = base_dir / "assets" / "play_store" / "feature_graphic.png"
    screenshot_dir = base_dir / "assets" / "play_store" / "screenshots"
    screenshots = sorted(list(screenshot_dir.glob("*_hires.png")))

    # 1. Create a new edit
    print("Creating edit...")
    edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit["id"]
    print(f"  Edit ID: {edit_id}")

    try:
        # 2. Update Text (Name change)
        update_listing(service, edit_id)

        # 3. Upload App Icon
        if icon_path.exists():
            upload_images(service, edit_id, 'icon', [icon_path])
        
        # 4. Upload Feature Graphic
        if feature_graphic_path.exists():
            upload_images(service, edit_id, 'featureGraphic', [feature_graphic_path])

        # 5. Upload Screenshots
        if screenshots:
            upload_images(service, edit_id, 'phoneScreenshots', screenshots)

        # 6. Commit the edit
        print("\nCommitting edit...")
        service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
        print("  ✅ Edit committed successfully!")
        print("\n🎉 All assets and metadata uploaded to Play Store.")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        # Edits are automatically discarded if not committed

if __name__ == "__main__":
    main()
