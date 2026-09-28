import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/data/user_state_service.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_providers.dart';
import 'package:flock_sense/features/auth/presentation/screens/login_screen.dart';
import 'package:flock_sense/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

/// Wrapper widget that handles routing based on user authentication state.
/// Uses Riverpod providers to manage state reactively with zero white-screen hangs.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  /// Map user state to corresponding UI screen
  Widget _buildScreen(UserState state) {
    switch (state) {
      case UserState.unauthenticated:
        return const LoginScreen();
      case UserState.onboarding:
        return const OnboardingScreen();
      case UserState.farmSetup:
        // Farm setup should only open from explicit Farm flow actions.
        return const MainShellScreen();
      case UserState.authenticated:
        return const MainShellScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Safely check current Firebase Auth user
    User? currentAuthUser;
    try {
      currentAuthUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    // Watch the user state stream for real-time updates
    final userStateAsync = ref.watch(userStateStreamProvider);

    return userStateAsync.when(
      // Loading state: If user is signed into Firebase Auth, route immediately to MainShellScreen
      // instead of stalling on a blank white screen.
      loading: () {
        if (currentAuthUser != null) {
          return const MainShellScreen();
        }
        return const _BrandedSplashLoading();
      },

      // Data loaded successfully
      data: (userState) => _buildScreen(userState),

      // Error state: If signed in, keep the user on MainShellScreen rather than showing an error screen
      error: (error, stackTrace) {
        debugPrint('AuthWrapper error: $error');
        if (currentAuthUser != null) {
          return const MainShellScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class _BrandedSplashLoading extends StatelessWidget {
  const _BrandedSplashLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2D1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21.5),
                child: Image.asset(
                  'assets/images/flocksense_app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'FlockSense',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Smart poultry farm management',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

