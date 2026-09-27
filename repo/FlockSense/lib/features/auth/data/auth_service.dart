import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── Standard sign-in ────────────────────────────────────────────────────

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final r = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return r.user!;
  }

  static Future<UserCredential> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final auth = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      final userDocRef = _db.collection('users').doc(user.uid);
      final existingSnapshot = await userDocRef.get();
      final existingData = existingSnapshot.data() ?? <String, dynamic>{};

      final profileData = <String, dynamic>{
        'uid': user.uid,
        'name': user.displayName ?? existingData['name'] ?? '',
        'email': user.email ?? existingData['email'] ?? '',
        'phone': user.phoneNumber ?? existingData['phone'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existingSnapshot.exists) {
        profileData.addAll({
          'role': 'owner',
          'hasCompletedOnboarding': false,
          'hasFarm': false,
          'activeFarmId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await userDocRef.set(profileData, SetOptions(merge: true));
    }
    return userCredential;
  }

  // ── Authentication Methods & Capabilities ──────────────────────────────
  /// Supported authentication methods in FlockSense.
  static const bool isGoogleAuthAvailable = true;
  static const bool isPhoneOtpAvailable = true;
  static const bool isEmailPasswordAvailable = true;

  /// Email OTP is supported via backend Cloud Functions (sendEmailOtp / verifyEmailOtp).
  static const bool isEmailOtpAvailable = true;

  // ── Email OTP (Backend Callable Cloud Functions) ──────────────────────────
  /// Sends an Email OTP via secure Cloud Functions backend.
  static Future<String> sendEmailOtp(String email) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendEmailOtp');
      final result = await callable.call({'email': email.trim().toLowerCase()});
      final data = result.data;
      if (data is Map) {
        return data['message'] as String? ?? 'Verification code sent';
      }
      return 'Verification code sent';
    } catch (e) {
      throw Exception('Failed to send verification code: $e');
    }
  }

  /// Verifies an Email OTP securely via Cloud Functions.
  static Future<bool> verifyEmailOtp(String email, String entered) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyEmailOtp');
      final result = await callable.call({
        'email': email.trim().toLowerCase(),
        'otp': entered.trim(),
      });
      final data = result.data;
      if (data is Map) {
        return (data['verified'] as bool?) ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Phone OTP (Firebase phone auth) ──────────────────────────────────────

  static Future<String> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String err) onError,
  }) {
    final comp = Completer<String>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) {
        // Android auto-retrieval: credential is already verified.
        // Sign in directly instead of treating credential as SMS code.
        _auth
            .signInWithCredential(cred)
            .then((_) {
              if (!comp.isCompleted) comp.complete('auto-verified');
            })
            .catchError((e) {
              if (!comp.isCompleted) comp.completeError(e);
            });
      },
      verificationFailed: (e) {
        onError(mapAuthException(e));
        if (!comp.isCompleted) comp.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!comp.isCompleted) comp.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {
        if (!comp.isCompleted) comp.complete('');
      },
    );

    return comp.future;
  }

  static Future<bool> verifyPhoneOtp(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(cred);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Create account (after OTP verified) ─────────────────────────────────

  static Future<User> createAccount({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final r = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = r.user!;
    await user.updateDisplayName(name.trim());

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone?.trim() ?? '',
      'role': 'owner',
      'hasCompletedOnboarding': false,
      'hasFarm': false,
      'activeFarmId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return user;
  }

  // Alias kept so nothing else breaks.
  static Future<User> register({
    required String name,
    required String email,
    required String password,
  }) => createAccount(name: name, email: email, password: password);

  // ── Misc ─────────────────────────────────────────────────────────────────

  static Future<void> sendPasswordReset({required String email}) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  static Future<void> logout() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  static String mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }

  static String mapFirebaseException(FirebaseException e) {
    if (e is FirebaseAuthException) return mapAuthException(e);
    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. Check your Firestore rules.';
      case 'unavailable':
        return 'Service unavailable. Try again.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}
