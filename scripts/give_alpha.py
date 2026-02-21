import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate('firebase_admin_key.json')
# check if default app is initialized
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

profiles_ref = db.collection('profiles')
doc_ref = profiles_ref.document('25l0NSTIwcXpmASBcXdLESGg2ji1')

doc = doc_ref.get()
if doc.exists:
    doc_ref.update({'isAlphaTester': True})
    print("Successfully updated isAlphaTester for Sam!")
else:
    print("Document not found!")
