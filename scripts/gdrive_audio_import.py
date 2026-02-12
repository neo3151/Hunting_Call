#!/usr/bin/env python3
"""
Google Drive Audio Import Script
=================================
Pulls audio files (.wav, .mp3) from a Google Drive account
and saves them locally with metadata .md files.

Target account: pongownsyou@gmail.com

Setup:
  1. Enable "Google Drive API" in Google Cloud Console
  2. Add pongownsyou@gmail.com as a test user in OAuth consent screen
  3. gdrive_credentials.json should be in scripts/ directory
  4. pip install -r requirements-gmail.txt  (same deps)
  5. python gdrive_audio_import.py
"""

import os
import sys
import re
import io
from datetime import datetime
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

# --- Configuration ---
SCOPES = ['https://www.googleapis.com/auth/drive.readonly']
TARGET_ACCOUNT = 'pongownsyou@gmail.com'
AUDIO_MIME_TYPES = {
    'audio/wav': '.wav',
    'audio/x-wav': '.wav',
    'audio/wave': '.wav',
    'audio/mpeg': '.mp3',
    'audio/mp3': '.mp3',
}
AUDIO_EXTENSIONS = {'.wav', '.mp3'}

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
OUTPUT_DIR = PROJECT_ROOT / 'assets' / 'audio' / 'gdrive_imports'
CREDENTIALS_FILE = SCRIPT_DIR / 'gdrive_credentials.json'
TOKEN_FILE = SCRIPT_DIR / 'gdrive_token.json'


def sanitize_filename(name: str) -> str:
    """Remove invalid characters from a filename."""
    name = re.sub(r'[<>:"/\\|?*]', '_', name)
    name = re.sub(r'\s+', '_', name)
    name = re.sub(r'_+', '_', name)
    return name.strip('_. ')


def authenticate():
    """Authenticate with Google Drive API using OAuth."""
    creds = None

    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("Refreshing expired token...")
            creds.refresh(Request())
        else:
            if not CREDENTIALS_FILE.exists():
                print(f"ERROR: gdrive_credentials.json not found at: {CREDENTIALS_FILE}")
                print(f"\nSetup:")
                print(f"  1. Go to https://console.cloud.google.com/")
                print(f"  2. Enable 'Google Drive API'")
                print(f"  3. Create OAuth 2.0 Client ID (Desktop app)")
                print(f"  4. Download credentials -> rename to gdrive_credentials.json")
                print(f"  5. Place in {SCRIPT_DIR}")
                sys.exit(1)

            print(f"Authorizing with Google Drive API...")
            print(f"Please sign in with: {TARGET_ACCOUNT}")
            print(f"A browser window will open.\n")

            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_FILE), SCOPES,
            )
            creds = flow.run_local_server(
                port=0,
                login_hint=TARGET_ACCOUNT,
                prompt='consent',
            )

        with open(TOKEN_FILE, 'w') as f:
            f.write(creds.to_json())
        print("Token saved for future use.")

    return build('drive', 'v3', credentials=creds)


def list_folders(service):
    """List all folders in the Drive to help user pick."""
    print("\nListing top-level folders in Drive...\n")
    
    results = service.files().list(
        q="mimeType='application/vnd.google-apps.folder' and 'root' in parents and trashed=false",
        fields="files(id, name)",
        orderBy="name",
        pageSize=100,
    ).execute()
    
    folders = results.get('files', [])
    
    if not folders:
        print("  No folders found in root.")
    else:
        for i, folder in enumerate(folders, 1):
            print(f"  {i}. {folder['name']} (ID: {folder['id']})")
    
    return folders


def find_audio_files(service, folder_id=None):
    """Find all audio files, optionally within a specific folder."""
    # Build query for audio files
    mime_queries = [f"mimeType='{mt}'" for mt in AUDIO_MIME_TYPES.keys()]
    mime_query = f"({' or '.join(mime_queries)})"
    
    # Also search by extension in filename for files with generic mime types
    ext_queries = [f"name contains '{ext}'" for ext in AUDIO_EXTENSIONS]
    ext_query = f"({' or '.join(ext_queries)})"
    
    query = f"({mime_query} or {ext_query}) and trashed=false"
    
    if folder_id:
        query = f"'{folder_id}' in parents and {query}"
    
    print(f"\nSearching for audio files...")
    
    all_files = []
    page_token = None
    
    while True:
        kwargs = {
            'q': query,
            'fields': "nextPageToken, files(id, name, mimeType, size, modifiedTime, description, parents)",
            'orderBy': "name",
            'pageSize': 100,
        }
        if page_token:
            kwargs['pageToken'] = page_token
        
        results = service.files().list(**kwargs).execute()
        files = results.get('files', [])
        all_files.extend(files)
        
        page_token = results.get('nextPageToken')
        if not page_token:
            break
    
    return all_files


def find_audio_recursive(service, folder_id, folder_name="root"):
    """Recursively find audio files in folder and all subfolders."""
    audio_files = []
    
    # Get audio files in this folder
    files = find_audio_in_folder(service, folder_id)
    for f in files:
        f['_folder_path'] = folder_name
    audio_files.extend(files)
    
    # Get subfolders
    results = service.files().list(
        q=f"'{folder_id}' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false",
        fields="files(id, name)",
        pageSize=100,
    ).execute()
    
    subfolders = results.get('files', [])
    for subfolder in subfolders:
        sub_path = f"{folder_name}/{subfolder['name']}"
        print(f"  Scanning: {sub_path}")
        sub_files = find_audio_recursive(service, subfolder['id'], sub_path)
        audio_files.extend(sub_files)
    
    return audio_files


def find_audio_in_folder(service, folder_id):
    """Find audio files in a specific folder (non-recursive)."""
    mime_queries = [f"mimeType='{mt}'" for mt in AUDIO_MIME_TYPES.keys()]
    mime_query = f"({' or '.join(mime_queries)})"
    ext_queries = [f"name contains '{ext}'" for ext in AUDIO_EXTENSIONS]
    ext_query = f"({' or '.join(ext_queries)})"
    
    query = f"'{folder_id}' in parents and ({mime_query} or {ext_query}) and trashed=false"
    
    all_files = []
    page_token = None
    
    while True:
        kwargs = {
            'q': query,
            'fields': "nextPageToken, files(id, name, mimeType, size, modifiedTime, description)",
            'pageSize': 100,
        }
        if page_token:
            kwargs['pageToken'] = page_token
        
        results = service.files().list(**kwargs).execute()
        files = results.get('files', [])
        all_files.extend(files)
        
        page_token = results.get('nextPageToken')
        if not page_token:
            break
    
    return all_files


def download_file(service, file_id, dest_path):
    """Download a file from Google Drive."""
    request = service.files().get_media(fileId=file_id)
    
    with open(dest_path, 'wb') as f:
        downloader = MediaIoBaseDownload(f, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()


def get_folder_path(service, file_info):
    """Get the folder path for a file."""
    if '_folder_path' in file_info:
        return file_info['_folder_path']
    
    parents = file_info.get('parents', [])
    if not parents:
        return 'root'
    
    try:
        parent = service.files().get(fileId=parents[0], fields='name').execute()
        return parent.get('name', 'unknown')
    except Exception:
        return 'unknown'


def get_comments(service, file_id):
    """Get comments on a file."""
    try:
        results = service.comments().list(
            fileId=file_id,
            fields="comments(content, author/displayName, createdTime)",
            pageSize=100,
        ).execute()
        return results.get('comments', [])
    except Exception:
        return []


def main():
    print("=" * 60)
    print("Google Drive Audio Import Script")
    print(f"Target: {TARGET_ACCOUNT}")
    print(f"Output: {OUTPUT_DIR}")
    print("=" * 60)

    # Authenticate
    service = authenticate()
    
    # List folders and let user choose
    folders = list_folders(service)
    
    print(f"\nOptions:")
    print(f"  0. Search ENTIRE Drive for audio files")
    for i, folder in enumerate(folders, 1):
        print(f"  {i}. Search in '{folder['name']}' only")
    
    try:
        choice = input(f"\nEnter choice (0-{len(folders)}): ").strip()
        choice = int(choice)
    except (ValueError, EOFError):
        choice = 0
    
    # Find audio files
    if choice == 0:
        print("\nSearching entire Drive (including subfolders)...")
        audio_files = find_audio_files(service)
        for f in audio_files:
            f['_folder_path'] = get_folder_path(service, f)
    elif 1 <= choice <= len(folders):
        selected = folders[choice - 1]
        print(f"\nSearching '{selected['name']}' and subfolders...")
        audio_files = find_audio_recursive(service, selected['id'], selected['name'])
    else:
        print("Invalid choice.")
        sys.exit(1)
    
    print(f"\nFound {len(audio_files)} audio file(s)")
    
    if not audio_files:
        print("No audio files found. Nothing to do.")
        return
    
    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Process each file
    imported_files = []
    skipped_files = []
    
    for i, file_info in enumerate(audio_files, 1):
        filename = file_info['name']
        file_id = file_info['id']
        size = int(file_info.get('size', 0))
        modified = file_info.get('modifiedTime', 'unknown')
        description = file_info.get('description', '')
        folder_path = file_info.get('_folder_path', 'unknown')
        
        stem = sanitize_filename(Path(filename).stem)
        ext = Path(filename).suffix.lower()
        if ext not in AUDIO_EXTENSIONS:
            # Try to determine from mime type
            mime = file_info.get('mimeType', '')
            ext = AUDIO_MIME_TYPES.get(mime, ext)
        
        safe_filename = f"{stem}{ext}"
        audio_path = OUTPUT_DIR / safe_filename
        notes_path = OUTPUT_DIR / f"{stem}.md"
        
        print(f"\n[{i}/{len(audio_files)}] {filename}")
        print(f"  Folder: {folder_path}")
        print(f"  Size:   {size / 1024:.1f} KB")
        
        # Skip if already downloaded
        if audio_path.exists():
            print(f"  SKIP - already exists")
            skipped_files.append(safe_filename)
            continue
        
        # Download
        print(f"  Downloading {safe_filename}...")
        try:
            download_file(service, file_id, audio_path)
        except Exception as e:
            print(f"  ERROR downloading: {e}")
            continue
        
        actual_size = audio_path.stat().st_size
        
        # Build notes
        note_content = f"# {stem}\n\n"
        note_content += f"**Source:** Google Drive ({TARGET_ACCOUNT})\n"
        note_content += f"**Drive Folder:** {folder_path}\n"
        note_content += f"**Original Filename:** {filename}\n"
        note_content += f"**File Size:** {actual_size / 1024:.1f} KB\n"
        note_content += f"**Last Modified:** {modified}\n\n"
        
        if description:
            note_content += f"## Description\n\n{description}\n\n"
        
        # Try to get comments
        try:
            comments = get_comments(service, file_id)
            if comments:
                note_content += "## Comments\n\n"
                for comment in comments:
                    author = comment.get('author', {}).get('displayName', 'Unknown')
                    content = comment.get('content', '')
                    created = comment.get('createdTime', '')
                    note_content += f"**{author}** ({created}):\n> {content}\n\n"
        except Exception:
            pass
        
        if not description and not note_content.endswith("## "):
            if "## Description" not in note_content and "## Comments" not in note_content:
                note_content += "## Notes\n\n*(No description or comments on this file)*\n"
        
        with open(notes_path, 'w', encoding='utf-8') as f:
            f.write(note_content)
        
        print(f"  Saved: {safe_filename} + {stem}.md")
        
        imported_files.append({
            'audio': safe_filename,
            'notes': f"{stem}.md",
            'folder': folder_path,
            'size_kb': actual_size / 1024,
        })
    
    # Generate manifest
    manifest_path = OUTPUT_DIR / '_import_manifest.md'
    manifest = f"# Google Drive Audio Import Manifest\n\n"
    manifest += f"**Account:** {TARGET_ACCOUNT}\n"
    manifest += f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
    manifest += f"**Files imported:** {len(imported_files)}\n"
    manifest += f"**Files skipped:** {len(skipped_files)}\n\n"
    
    if imported_files:
        manifest += "## Imported Files\n\n"
        manifest += "| Audio File | Notes | Drive Folder | Size |\n"
        manifest += "|-----------|-------|-------------|------|\n"
        for f in imported_files:
            manifest += f"| {f['audio']} | {f['notes']} | {f['folder']} | {f['size_kb']:.1f} KB |\n"
        manifest += "\n"
    
    if skipped_files:
        manifest += "## Skipped Files (already exist)\n\n"
        for f in skipped_files:
            manifest += f"- {f}\n"
    
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(manifest)
    
    print(f"\n{'=' * 60}")
    print(f"Import complete!")
    print(f"  Imported: {len(imported_files)} file(s)")
    print(f"  Skipped:  {len(skipped_files)} file(s)")
    print(f"  Output:   {OUTPUT_DIR}")
    print(f"  Manifest: {manifest_path}")
    print(f"{'=' * 60}")


if __name__ == '__main__':
    main()
