import 'package:flutter/material.dart';
import 'package:flock_sense/features/auth/presentation/screens/auth_wrapper.dart';
import 'package:flock_sense/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flock_sense/features/auth/presentation/screens/login_screen.dart';
import 'package:flock_sense/features/auth/presentation/screens/register_screen.dart';
import 'package:flock_sense/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flock_sense/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String farmSetup = '/farm-setup';
  static const String farms = '/farms';
  static const String dashboard = '/dashboard';
  static const String main = '/main';

  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    initial: (context) => const AuthWrapper(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    onboarding: (context) => const OnboardingScreen(),
    farmSetup: (context) => const FarmSetupScreen(),
    farms: (context) => const FarmListScreen(),
    dashboard: (context) => const DashboardScreen(),
    main: (context) => const MainShellScreen(),
  };
}
