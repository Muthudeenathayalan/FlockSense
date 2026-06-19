import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/data/user_state_service.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_providers.dart';
import 'package:flock_sense/features/auth/presentation/screens/login_screen.dart';
import 'package:flock_sense/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

/// Wrapper widget that handles routing based on user authentication state
/// Uses Riverpod providers to manage state reactively
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
    // Watch the user state stream for real-time updates
    final userStateAsync = ref.watch(userStateStreamProvider);

    return userStateAsync.when(
      // Loading state
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      // Data loaded successfully
      data: (userState) => _buildScreen(userState),

      // Error state
      error: (error, stackTrace) {
        debugPrint('AuthWrapper error: $error');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('An error occurred'),
                const SizedBox(height: 8),
                Text(
                  'Please restart the app',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

