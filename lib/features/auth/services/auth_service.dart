// lib/features/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with username + password.
  /// Username is mapped to an email: username@keepyourvow.app
  Future<User?> signUpWithUsername({
    required String username,
    required String password,
  }) async {
    final email = _usernameToEmail(username);
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Store the display name as the username
    await cred.user?.updateDisplayName(username);
    return cred.user;
  }

  /// Sign in with username + password.
  Future<User?> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final email = _usernameToEmail(username);
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  /// Sign in (or sign up) with Google.
  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return cred.user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _usernameToEmail(String username) =>
      '${username.trim().toLowerCase()}@keepyourvow.app';
}
