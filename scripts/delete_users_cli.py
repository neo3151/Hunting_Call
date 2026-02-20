#!/usr/bin/env python3
"""
Bulk delete all users from Firebase Authentication using Firebase CLI credentials.
This avoids 'InsufficientPermissionError' from service accounts.
Usage: python3 scripts/delete_users_cli.py
"""

import os
import sys
import subprocess
import json
import requests

def main():
    print("⏳ Getting Firebase CLI access token...")
    try:
        token_proc = subprocess.run(['firebase', 'login:print-token'], capture_output=True, text=True, check=True)
        token = token_proc.stdout.strip()
    except Exception as e:
        print(f"❌ Error getting token: {e}")
        print("Please run 'firebase login' first.")
        sys.exit(1)

    # Get project ID
    project_id = "hunting-call-perfection"
    
    print(f"📋 Fetching all users for project '{project_id}'...")
    
    # Use Identity Platform / Auth export API
    # https://cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/batchGet
    # Actually, easier to use 'firebase auth:export' to get a CSV/JSON of UIDs
    
    export_file = "users_temp.json"
    print("📡 Exporting user list via CLI...")
    try:
        subprocess.run(['firebase', 'auth:export', export_file, '--format=json', '--project', project_id], check=True)
    except Exception as e:
        print(f"❌ Export failed: {e}")
        sys.exit(1)

    with open(export_file, 'r') as f:
        data = json.load(f)
        users = data.get('users', [])

    os.remove(export_file)

    uids = [u['localId'] for u in users]
    total = len(uids)

    if total == 0:
        print("✅ No users found. Already clean!")
        return

    print(f"⚠️  WARNING: You are about to delete {total} users permanently!")
    confirm = input("Type 'DELETE' to confirm: ")
    if confirm != 'DELETE':
        print("❌ Deletion cancelled.")
        return

    # Delete in batches via Admin API (using the CLI token)
    # The batch delete endpoint: 
    # POST https://identitytoolkit.googleapis.com/v1/projects/{projectId}/accounts:batchDelete
    
    print(f"🗑️  Deleting {total} users...")
    
    url = f"https://identitytoolkit.googleapis.com/v1/projects/{project_id}/accounts:batchDelete"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Batch size for this API is 1000
    for i in range(0, total, 1000):
        batch = uids[i:i+1000]
        payload = {"localIds": batch}
        
        resp = requests.post(url, headers=headers, json=payload)
        if resp.status_code == 200:
            print(f"  ✓ Deleted batch {i // 1000 + 1} ({len(batch)} users)")
        else:
            print(f"  ✗ Failed to delete batch: {resp.text}")

    print("\n🎉 Done! All users deleted.")

if __name__ == "__main__":
    main()
