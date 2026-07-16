import 'package:flutter/material.dart';
import 'package:flock_sense/features/auth/presentation/screens/auth_wrapper.dart';
import 'package:flock_sense/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flock_sense/features/auth/presentation/screens/login_screen.dart';
import 'package:flock_sense/features/auth/presentation/screens/registration_method_screen.dart';
import 'package:flock_sense/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register'; // → RegistrationMethodScreen
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String farmSetup = '/farm-setup';
  static const String farms = '/farms';
  static const String main = '/main';

  static final Map<String, WidgetBuilder> routes = {
    initial: (_) => const AuthWrapper(),
    login: (_) => const LoginScreen(),
    register: (_) =>
        const RegistrationMethodScreen(), // changed from RegisterScreen
    forgotPassword: (_) => const ForgotPasswordScreen(),
    onboarding: (_) => const OnboardingScreen(),
    farmSetup: (_) => const FarmSetupScreen(),
    farms: (_) => const FarmListScreen(),
    main: (_) => const MainShellScreen(),
  };
}
