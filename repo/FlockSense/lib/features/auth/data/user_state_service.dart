import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/onboarding/presentation/screens/onboarding_screen.dart';

enum UserState { unauthenticated, onboarding, farmSetup, authenticated }

class UserStateService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Resolves the current user's position in the onboarding flow.
  ///
  /// FIX: removed `GetOptions(source: Source.server)` — that option
  /// requires a live network round-trip and throws offline, causing
  /// every authenticated-but-offline user to be treated as unauthenticated
  /// and redirected to the login screen. The default source is
  /// Source.serverAndCache: it tries the server and falls back to the local
  /// Firestore disk cache when offline, which is the correct behaviour here.
  Future<UserState> getUserState() async {
    final user = _auth.currentUser;
    if (user == null) return UserState.unauthenticated;

    try {
      // Add a 3-second timeout so it never hangs or leaves the user on a white screen
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (!doc.exists || doc.data() == null) {
        // Automatically initialize missing user profile document so new logins enter the app
        _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'hasCompletedOnboarding': true,
          'hasFarm': false,
          'activeFarmId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((_) {});
        return UserState.farmSetup;
      }

      final data = doc.data()!;
      final onboarded = data['hasCompletedOnboarding'] as bool? ?? false;
      if (!onboarded) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final hasSeen =
              prefs.getBool(OnboardingScreen.hasSeenOnboardingKey) ?? false;
          if (hasSeen) {
            _firestore.collection('users').doc(user.uid).set({
              'hasCompletedOnboarding': true,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true)).catchError((_) {});
          } else {
            return UserState.onboarding;
          }
        } catch (_) {
          return UserState.onboarding;
        }
      }

      final hasFarm = data['hasFarm'] as bool? ?? false;
      final activeFarmId = data['activeFarmId'] as String?;
      if (!hasFarm || (activeFarmId?.isEmpty ?? true)) {
        return UserState.farmSetup;
      }

      return UserState.authenticated;
    } catch (_) {
      // If Firestore fails even with cache or times out, keep the user authenticated
      // rather than kicking them to login or stuck on white screen — they're signed in.
      if (_auth.currentUser != null) return UserState.authenticated;
      return UserState.unauthenticated;
    }
  }

  Stream<UserState> getUserStateStream() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield UserState.unauthenticated;
      } else {
        // Instantly yield authenticated so the UI never hangs on a blank loading screen
        yield UserState.authenticated;
        yield* _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .asyncMap((_) => getUserState())
            .handleError((e) {
              return UserState.authenticated;
            });
      }
    });
  }

  bool isAuthenticated() => _auth.currentUser != null;
  User? getCurrentUser() => _auth.currentUser;
  Future<void> signOut() => _auth.signOut();
}
