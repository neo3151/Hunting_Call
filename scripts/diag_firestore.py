import firebase_admin
from firebase_admin import credentials, firestore

def diagnose():
    cred = credentials.Certificate('scripts/service-account.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    
    print("🔍 Checking 'profiles' collection...")
    profiles_ref = db.collection('profiles')
    docs = profiles_ref.stream()
    
    found = False
    for doc in docs:
        found = True
        data = doc.to_dict()
        print(f"ID: {doc.id} | Name: {data.get('name')} | Email: {data.get('email')}")
    
    if not found:
        print("📭 No profiles found in Firestore.")

if __name__ == "__main__":
    diagnose()
