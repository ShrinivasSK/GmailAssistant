import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
  );

  // Keys for storage
  static const String _accessTokenKey = 'gmail_access_token';
  static const String _emailKey = 'user_email';

  // Get stored credentials
  Future<Map<String, String?>> getCredentials() async {
    return {
      'accessToken': await _storage.read(key: _accessTokenKey),
      'email': await _storage.read(key: _emailKey),
    };
  }

  // Save credentials
  Future<void> saveCredentials({
    required String accessToken,
    required String email,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _emailKey, value: email);
  }

  // Clear credentials on logout
  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    final credentials = await getCredentials();
    return credentials['accessToken'] != null;
  }

  // Handle sign in
  Future<bool> handleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        // Save credentials
        await saveCredentials(
          accessToken: auth.accessToken!,
          email: account.email,
        );
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  // Handle sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await clearCredentials();
  }
} 