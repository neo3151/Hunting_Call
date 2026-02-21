import firebase_admin
from firebase_admin import credentials, auth, firestore

def main():
    cred = credentials.Certificate('scripts/service-account.json')
    firebase_admin.initialize_app(cred)
    try:
        user = auth.get_user_by_email('pongownsyou@gmail.com')
        uid = user.uid
        print(f"Found user with UID: {uid}", flush=True)
        db = firestore.client()
        db.collection('profiles').document(uid).set({'isAlphaTester': True}, merge=True)
        print("Successfully updated isAlphaTester to True.", flush=True)
    except Exception as e:
        print(f"Error: {e}", flush=True)

if __name__ == '__main__':
    main()
