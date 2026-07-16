import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

// Quotes shown to first-time users on the welcome carousel.
const _quotes = [
  (
    icon: Icons.agriculture,
    headline: 'Welcome to FlockSense',
    body:
        'The smart way to manage your poultry farms — from a single shed to an entire flock operation.',
    accent: Color(0xFF0A5C38),
  ),
  (
    icon: Icons.insights,
    headline: 'Data-driven farming',
    body:
        '"Good farmers know their land. Great farmers know their numbers." Track feed, mortality, growth and more — every day.',
    accent: Color(0xFF1B6B8A),
  ),
  (
    icon: Icons.cloud_sync,
    headline: 'Works offline too',
    body:
        'No internet? No problem. Your records are saved locally and sync automatically when you come back online.',
    accent: Color(0xFF5C3D0A),
  ),
  (
    icon: Icons.health_and_safety,
    headline: 'Keep your flock healthy',
    body:
        '"A healthy bird is a profitable bird." Set vaccination reminders, track medicine usage and monitor daily health scores.',
    accent: Color(0xFF1A5C1A),
  ),
  (
    icon: Icons.emoji_events,
    headline: "You're all set!",
    body:
        'Create your first farm and start your journey towards smarter, more profitable poultry farming.',
    accent: Color(0xFF6B3D0A),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Mark onboarding complete in Firestore so this screen never shows again.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'hasCompletedOnboarding': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    if (mounted) {
      // Go to AuthWrapper — it will re-evaluate state and send user to
      // farmSetup / main shell as appropriate.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _quotes.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _quotes.length,
                itemBuilder: (_, i) => _QuotePage(data: _quotes[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _quotes.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          ),
                    child: Text(isLast ? "Let's go!" : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotePage extends StatelessWidget {
  const _QuotePage({required this.data});
  final ({IconData icon, String headline, String body, Color accent}) data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle with gradient
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [data.accent, data.accent.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(data.icon, size: 54, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Text(
            data.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15.5,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
