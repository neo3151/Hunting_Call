import firebase_admin
from firebase_admin import credentials, auth

def main():
    cred = credentials.Certificate('scripts/service-account.json')
    firebase_admin.initialize_app(cred)
    user = auth.get_user_by_email('pongownsyou@gmail.com')
    auth.update_user(user.uid, password='alpha_password_123')
    print("Password updated successfully.")

if __name__ == '__main__':
    main()
