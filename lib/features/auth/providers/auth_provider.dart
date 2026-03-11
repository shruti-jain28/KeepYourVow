// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Streams the current Firebase user (null = signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// Notifier for auth actions (sign in, sign up, sign out).
final authNotifierProvider =
    NotifierProvider<AuthNotifier, void>(AuthNotifier.new);

class AuthNotifier extends Notifier<void> {
  @override
  void build() {}

  final _auth = AuthService.instance;

  Future<String?> signUpWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      await _auth.signUpWithUsername(username: username, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('signUpWithUsername FirebaseAuthException: ${e.code}');
      return _mapErrorCode(e.code);
    } on FirebaseException catch (e) {
      debugPrint('signUpWithUsername FirebaseException: ${e.code}');
      return _mapErrorCode(e.code);
    } catch (e) {
      debugPrint('signUpWithUsername error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      await _auth.signInWithUsername(username: username, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithUsername FirebaseAuthException: ${e.code}');
      return _mapErrorCode(e.code);
    } on FirebaseException catch (e) {
      debugPrint('signInWithUsername FirebaseException: ${e.code}');
      return _mapErrorCode(e.code);
    } catch (e) {
      debugPrint('signInWithUsername error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final user = await _auth.signInWithGoogle();
      if (user == null) return 'Sign in cancelled';
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithGoogle FirebaseAuthException: ${e.code}');
      return _mapErrorCode(e.code);
    } on FirebaseException catch (e) {
      debugPrint('signInWithGoogle FirebaseException: ${e.code}');
      return _mapErrorCode(e.code);
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This username is already taken.';
      case 'invalid-email':
        return 'Invalid username format.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with that username.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'channel-error':
        return 'Please fill in all fields.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please enable it in Firebase Console.';
      default:
        return 'Error ($code). Please try again.';
    }
  }
}
