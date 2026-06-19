import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user!;
  }

  static String mapAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return exception.message ?? 'Something went wrong. Please try again.';
    }
  }

  static String mapFirebaseException(FirebaseException exception) {
    if (exception is FirebaseAuthException) {
      return mapAuthException(exception);
    }

    switch (exception.code) {
      case 'permission-denied':
        return 'Unable to save your account. Please make sure app permissions are allowed.';
      case 'unavailable':
        return 'Firebase service unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      default:
        return exception.message ?? 'Something went wrong. Please try again.';
    }
  }

  static Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user!;
    await user.updateDisplayName(name);
    final userData = {
      'uid': user.uid,
      'name': name,
      'email': user.email ?? email,
      'role': 'owner',
      'hasCompletedOnboarding': false,
      'hasFarm': false,
      'activeFarmId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('users').doc(user.uid).set(
          userData,
          SetOptions(merge: true),
        );
    return user;
  }

  static Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
