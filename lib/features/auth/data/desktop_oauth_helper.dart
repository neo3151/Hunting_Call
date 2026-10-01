import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:outcall/core/utils/app_logger.dart';

class DesktopOAuthHelper {
  // Desktop app OAuth 2.0 credentials — loaded at runtime from a bundled,
  // git-ignored secrets file so they never land in source control.
  // Copy assets/secrets/oauth_desktop.json.example to oauth_desktop.json
  // and fill in the values from Google Cloud Console.
  static String? _desktopClientId;
  static String? _desktopClientSecret;

  static Future<void> _ensureCredentials() async {
    if (_desktopClientId != null && _desktopClientSecret != null) return;
    final raw =
        await rootBundle.loadString('assets/secrets/oauth_desktop.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _desktopClientId = json['client_id'] as String;
    _desktopClientSecret = json['client_secret'] as String;
  }

  // Firebase Web config — used for Apple Sign-In bridge only.
  static const String _firebaseApiKey = 'AIzaSyBGJiaNDKA879CepT1Ymgp2pkBB_pm_FZs';
  static const String _authDomain = 'hunting-call-perfection.firebaseapp.com';
  static const String _projectId = 'hunting-call-perfection';
  static const String _messagingSenderId = '654995904748';
  static const String _appId = '1:654995904748:web:5079119d9b07508082adc9';

  // PKCE helpers
  static String _generateVerifier() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static String _generateChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  // Google Sign-In via Desktop PKCE (RFC 8252)
  // Opens Safari directly to accounts.google.com. Google redirects back to
  // http://localhost:PORT/callback?code=... which is allowed for Desktop client IDs.
  // Token exchange is done entirely in Dart — no popup, no redirect loop.
  static Future<UserCredential> signInWithGoogleDesktop() async {
    AppLogger.d('🌐 Google PKCE flow starting...');
    await _ensureCredentials();

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final redirectUri = 'http://localhost:$port/callback';

    final verifier = _generateVerifier();
    final challenge = _generateChallenge(verifier);

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': _desktopClientId!,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
    });

    AppLogger.d('🌐 Opening Google auth URL on port $port');

    final completer = Completer<UserCredential>();

    final sub = server.listen((HttpRequest req) async {
      if (req.uri.path != '/callback') {
        req.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      final code = req.uri.queryParameters['code'];
      final error = req.uri.queryParameters['error'];

      if (error != null || code == null || code.isEmpty) {
        _respond(req, _cancelledHtml());
        if (!completer.isCompleted) {
          completer.completeError(
              Exception('Google Sign-In cancelled: ${error ?? 'no code'}'));
        }
        return;
      }

      try {
        // Exchange auth code for tokens using http package
        AppLogger.d('🌐 Exchanging code for tokens (redirect_uri=$redirectUri)');
        final tokenRes = await http.post(
          Uri.parse('https://oauth2.googleapis.com/token'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'client_id': _desktopClientId!,
            'client_secret': _desktopClientSecret!,
            'code': code,
            'code_verifier': verifier,
            'grant_type': 'authorization_code',
            'redirect_uri': redirectUri,
          },
        );

        AppLogger.d('🌐 Token response status: ${tokenRes.statusCode}');
        AppLogger.d('🌐 Token response body: ${tokenRes.body}');

        final json = jsonDecode(tokenRes.body) as Map<String, dynamic>;
        final idToken = json['id_token'] as String?;
        final accessToken = json['access_token'] as String?;

        if (idToken == null) {
          final err = json['error_description'] ??
              json['error'] ??
              'No id_token in response';
          _respond(req, _errorHtml(err.toString()));
          if (!completer.isCompleted) {
            completer.completeError(
                Exception('Google token exchange failed: $err'));
          }
          return;
        }

        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );
        final userCred =
            await FirebaseAuth.instance.signInWithCredential(credential);
        _respond(req, _successHtml());

        AppLogger.d('✅ Google PKCE Sign-In complete: ${userCred.user?.email}');
        if (!completer.isCompleted) completer.complete(userCred);
      } catch (e) {
        _respond(req, _errorHtml(e.toString()));
        if (!completer.isCompleted) completer.completeError(e);
      }
    });

    final launched =
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    if (!launched) {
      await sub.cancel();
      await server.close(force: true);
      throw Exception('Could not launch browser for Google Sign-In.');
    }

    try {
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException('Google Sign-In timed out.'),
      );
    } finally {
      await sub.cancel();
      await server.close(force: true);
    }
  }

  // Apple Sign-In via Firebase popup bridge.
  // Apple OAuth routes through Firebase's pre-registered firebaseapp.com handler —
  // no redirect_uri_mismatch. Popup is triggered by a real click, so Safari allows it.
  static Future<UserCredential> signInWithAppleDesktop() async {
    AppLogger.d('🌐 Apple popup bridge starting...');

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final startUrl = Uri.parse('http://localhost:$port/auth');

    final completer = Completer<UserCredential>();

    final sub = server.listen((HttpRequest req) async {
      final path = req.uri.path;

      if (path == '/auth') {
        _respond(req, _appleBridgeHtml());
      } else if (path == '/callback') {
        final token = req.uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          try {
            final credential =
                OAuthProvider('apple.com').credential(idToken: token);
            final userCred =
                await FirebaseAuth.instance.signInWithCredential(credential);
            _respond(req, _successHtml());
            AppLogger.d('✅ Apple Sign-In complete: ${userCred.user?.email}');
            if (!completer.isCompleted) completer.complete(userCred);
          } catch (e) {
            _respond(req, _errorHtml(e.toString()));
            if (!completer.isCompleted) completer.completeError(e);
          }
        } else {
          _respond(req, _errorHtml('No token received from Apple.'));
          if (!completer.isCompleted) {
            completer.completeError(Exception('No token received from Apple.'));
          }
        }
      } else {
        req.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    });

    final launched =
        await launchUrl(startUrl, mode: LaunchMode.externalApplication);
    if (!launched) {
      await sub.cancel();
      await server.close(force: true);
      throw Exception('Could not launch browser for Apple Sign-In.');
    }

    try {
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException('Apple Sign-In timed out.'),
      );
    } finally {
      await sub.cancel();
      await server.close(force: true);
    }
  }

  // HTML helpers

  static void _respond(HttpRequest req, String html) {
    req.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }

  static String _appleBridgeHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Outcall - Sign In with Apple</title>
  <style>
    body{background:#121814;color:#fff;font-family:system-ui,-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
    .card{background:#1c241f;padding:40px;border-radius:16px;text-align:center;box-shadow:0 8px 24px rgba(0,0,0,.4);max-width:420px;width:90%}
    .icon{font-size:48px;margin-bottom:12px}
    h2{color:#fff;font-size:24px;margin:0 0 8px}
    p{color:#a3a3a3;font-size:14px;line-height:1.5;margin-bottom:24px}
    .btn{background:#4ade80;color:#121814;font-weight:bold;border:none;padding:16px 32px;border-radius:12px;font-size:16px;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;gap:10px;width:100%;box-sizing:border-box;transition:background .2s}
    .btn:hover{background:#22c55e}
    .btn:disabled{opacity:.6;cursor:not-allowed}
    .spinner{border:3px solid rgba(255,255,255,.1);border-left-color:#121814;border-radius:50%;width:20px;height:20px;animation:spin 1s linear infinite;display:none}
    @keyframes spin{to{transform:rotate(360deg)}}
    .err{color:#f87171;font-size:13px;margin-top:16px;display:none}
  </style>
  <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-auth-compat.js"></script>
</head>
<body>
  <div class="card">
    <div class="icon">🍎</div>
    <h2>Sign in with Apple</h2>
    <p>Click below to authorize your Outcall desktop account.</p>
    <button id="btn" class="btn" onclick="doSignIn()">
      <div id="spin" class="spinner"></div>
      <span id="lbl">Continue with Apple</span>
    </button>
    <div id="err" class="err"></div>
  </div>
  <script>
    firebase.initializeApp({
      apiKey: "$_firebaseApiKey",
      authDomain: "$_authDomain",
      projectId: "$_projectId",
      messagingSenderId: "$_messagingSenderId",
      appId: "$_appId"
    });
    function doSignIn() {
      var btn = document.getElementById('btn');
      var lbl = document.getElementById('lbl');
      var spin = document.getElementById('spin');
      var err = document.getElementById('err');
      btn.disabled = true;
      lbl.innerText = 'Signing In...';
      spin.style.display = 'inline-block';
      err.style.display = 'none';
      var provider = new firebase.auth.OAuthProvider('apple.com');
      provider.addScope('email');
      provider.addScope('name');
      firebase.auth().signInWithPopup(provider)
        .then(function(result) { return result.user.getIdToken(); })
        .then(function(token) {
          window.location.href = '/callback?token=' + encodeURIComponent(token);
        })
        .catch(function(e) {
          btn.disabled = false;
          lbl.innerText = 'Continue with Apple';
          spin.style.display = 'none';
          err.innerText = e.message || 'Sign-in failed.';
          err.style.display = 'block';
        });
    }
  </script>
</body>
</html>
''';
  }

  static String _successHtml() {
    return '''
<!DOCTYPE html><html>
<head><title>Outcall - Signed In</title>
<style>body{background:#121814;color:#fff;font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}.card{background:#1c241f;padding:40px;border-radius:16px;text-align:center;max-width:400px}h2{color:#4ade80}p{color:#a3a3a3;font-size:14px}</style>
</head><body>
<div class="card">
  <div style="font-size:48px;margin-bottom:16px">🌲</div>
  <h2>Sign-In Successful!</h2>
  <p>You can close this window and return to <strong>Outcall</strong>.</p>
</div>
<script>setTimeout(function(){window.close();},2000);</script>
</body></html>
''';
  }

  static String _cancelledHtml() {
    return '''
<!DOCTYPE html><html>
<head><title>Outcall - Cancelled</title>
<style>body{background:#121814;color:#fff;font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}.card{background:#1c241f;padding:40px;border-radius:16px;text-align:center;max-width:400px}h2{color:#f87171}p{color:#a3a3a3;font-size:14px}</style>
</head><body>
<div class="card">
  <h2>Sign-In Cancelled</h2>
  <p>You closed the sign-in window. You can try again in Outcall.</p>
</div>
</body></html>
''';
  }

  static String _errorHtml(String error) {
    final safe = error.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    return '''
<!DOCTYPE html><html>
<head><title>Outcall - Error</title>
<style>body{background:#121814;color:#fff;font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}.card{background:#1c241f;padding:40px;border-radius:16px;text-align:center;max-width:420px}h2{color:#f87171}p{color:#a3a3a3;font-size:13px;word-break:break-word}</style>
</head><body>
<div class="card">
  <h2>Sign-In Failed</h2>
  <p>$safe</p>
  <p>Close this tab and try again in Outcall.</p>
</div>
</body></html>
''';
  }
}
