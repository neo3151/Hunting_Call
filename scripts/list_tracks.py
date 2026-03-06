#!/usr/bin/env python3
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

PACKAGE_NAME = 'com.neo3151.huntingcalls'
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']
TOKEN_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'play_token.json')

creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
if not creds.valid:
    creds.refresh(Request())
service = build('androidpublisher', 'v3', credentials=creds)

edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
eid = edit['id']

tracks = service.edits().tracks().list(packageName=PACKAGE_NAME, editId=eid).execute()
for t in tracks.get('tracks', []):
    track_name = t['track']
    print(f'Track: {track_name}')
    for r in t.get('releases', []):
        name = r.get('name', '')
        status = r.get('status', '')
        codes = r.get('versionCodes', [])
        print(f'  Release: {name} status={status} versions={codes}')
