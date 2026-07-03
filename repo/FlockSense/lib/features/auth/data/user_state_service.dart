import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // No GetOptions — uses Firestore default (server, fall back to cache).
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data() == null) return UserState.onboarding;

      final data = doc.data()!;
      final onboarded = data['hasCompletedOnboarding'] as bool? ?? false;
      if (!onboarded) return UserState.onboarding;

      final hasFarm = data['hasFarm'] as bool? ?? false;
      final activeFarmId = data['activeFarmId'] as String?;
      if (!hasFarm || (activeFarmId?.isEmpty ?? true)) return UserState.farmSetup;

      return UserState.authenticated;
    } catch (_) {
      // If Firestore fails even with cache, keep the user authenticated
      // rather than kicking them to login — they're signed in, just offline.
      if (_auth.currentUser != null) return UserState.authenticated;
      return UserState.unauthenticated;
    }
  }

  Stream<UserState> getUserStateStream() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield UserState.unauthenticated;
      } else {
        yield* _firestore
            .collection('users').doc(user.uid)
            .snapshots()
            .asyncMap((_) => getUserState());
      }
    });
  }

  bool isAuthenticated() => _auth.currentUser != null;
  User? getCurrentUser() => _auth.currentUser;
  Future<void> signOut() => _auth.signOut();
}
