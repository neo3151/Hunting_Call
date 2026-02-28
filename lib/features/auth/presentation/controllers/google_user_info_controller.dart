import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores Google user info (email, displayName) after sign-in
/// This is used by AuthWrapper to create profiles with the correct email
class GoogleUserInfo {
  final String? email;
  final String? displayName;

  GoogleUserInfo({this.email, this.displayName});
}

class GoogleUserInfoNotifier extends Notifier<GoogleUserInfo?> {
  @override
  GoogleUserInfo? build() => null;

  void setUserInfo(String? email, String? displayName) {
    state = GoogleUserInfo(email: email, displayName: displayName);
  }

  void clear() {
    state = null;
  }
}

final googleUserInfoProvider = NotifierProvider<GoogleUserInfoNotifier, GoogleUserInfo?>(GoogleUserInfoNotifier.new);
