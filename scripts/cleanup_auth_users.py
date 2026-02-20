#!/usr/bin/env python3
"""
Bulk delete all users from Firebase Authentication.
Requires: pip install firebase-admin
Usage: python3 scripts/cleanup_auth_users.py
"""

import os
import sys
try:
    import firebase_admin
    from firebase_admin import auth
except ImportError:
    print("❌ Error: firebase-admin not found.")
    print("Please install it with: pip install firebase-admin")
    sys.exit(1)

# Check for service account file
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT_PATH = os.path.join(SCRIPT_DIR, "service-account.json")

def main():
    if not os.path.exists(SERVICE_ACCOUNT_PATH):
        print(f"❌ Error: {SERVICE_ACCOUNT_PATH} not found.")
        print("\nTo use this script:")
        print("1. Go to Firebase Console > Project Settings > Service Accounts.")
        print("2. Click 'Generate new private key'.")
        print(f"3. Save the JSON file as '{SERVICE_ACCOUNT_PATH}'.")
        sys.exit(1)

    # Initialize Admin SDK
    cred = firebase_admin.credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)

    print("📋 Fetching all users...")
    
    users_to_delete = []
    page = auth.list_users()
    while page:
        for user in page.users:
            users_to_delete.append(user.uid)
        page = page.get_next_page()

    total = len(users_to_delete)
    if total == 0:
        print("✅ No users found in Authentication. Already clean!")
        return

    print(f"⚠️  WARNING: You are about to delete {total} users permanently!")
    confirm = input("Type 'DELETE' to confirm: ")
    
    if confirm != 'DELETE':
        print("❌ Deletion cancelled.")
        return

    print(f"🗑️  Deleting {total} users in batches of 1000...")
    
    # helper for batching
    def chunks(lst, n):
        for i in range(0, len(lst), n):
            yield lst[i:i + n]

    deleted_count = 0
    for chunk in chunks(users_to_delete, 1000):
        result = auth.delete_users(chunk)
        deleted_count += (len(chunk) - len(result.errors))
        print(f"  Progress: {deleted_count}/{total} deleted...")

    print(f"\n✅ Successfully deleted {deleted_count} users!")
    print("🎉 Firebase Authentication is now clean.")

if __name__ == "__main__":
    main()
