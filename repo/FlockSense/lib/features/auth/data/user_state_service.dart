import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enum to represent different user states in the app flow
enum UserState {
  /// User is not authenticated
  unauthenticated,

  /// User is authenticated but needs to complete onboarding
  onboarding,

  /// User has completed onboarding but needs to set up a farm
  farmSetup,

  /// User has completed onboarding and has an active farm (main app)
  authenticated,
}

/// Service that manages user state logic independently from UI
class UserStateService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Determines the current user's state in the app flow
  /// Returns [UserState.unauthenticated] if no user is logged in
  /// Returns [UserState.onboarding] if user hasn't completed onboarding
  /// Returns [UserState.farmSetup] if user hasn't set up a farm
  /// Returns [UserState.authenticated] if user is fully set up
  Future<UserState> getUserState() async {
    final currentUser = _auth.currentUser;

    // User is not authenticated
    if (currentUser == null) {
      return UserState.unauthenticated;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.server));

      // User document doesn't exist - needs onboarding
      if (!userDoc.exists || userDoc.data() == null) {
        return UserState.onboarding;
      }

      final data = userDoc.data()!;
      final hasCompletedOnboarding =
          data['hasCompletedOnboarding'] as bool? ?? false;

      // User hasn't completed onboarding
      if (!hasCompletedOnboarding) {
        return UserState.onboarding;
      }

      // User has onboarded but check for farm
      final hasFarm = data['hasFarm'] as bool? ?? false;
      final activeFarmId = data['activeFarmId'] as String?;

      // User needs to set up a farm
      if (!hasFarm || activeFarmId == null || activeFarmId.isEmpty) {
        return UserState.farmSetup;
      }

      // User is fully authenticated
      return UserState.authenticated;
    } catch (e) {
      // On error, treat as unauthenticated to show login
      return UserState.unauthenticated;
    }
  }

  /// Stream that emits user state changes in real-time
  /// Listens to both auth changes and user document changes
  Stream<UserState> getUserStateStream() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield UserState.unauthenticated;
      } else {
        // Listen to the user document for changes to onboarding/farm status
        yield* _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .asyncMap((_) => getUserState());
      }
    });
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get current authenticated user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
