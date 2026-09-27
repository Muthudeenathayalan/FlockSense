import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class OnboardingPillarData {
  const OnboardingPillarData({
    required this.badge,
    required this.headline,
    required this.subtitle,
    required this.description,
    required this.highlights,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String badge;
  final String headline;
  final String subtitle;
  final String description;
  final List<String> highlights;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
}

const List<OnboardingPillarData> _pillars = [
  OnboardingPillarData(
    badge: 'DAILY TELEMETRY & CLIMATE',
    headline: '30-Second Smart Logging',
    subtitle: 'Track mortality, feed, water & climate effortlessly',
    description:
        'Capture critical flock metrics in seconds. FlockSense monitors live mortality, water intake ratios, and Temperature-Humidity Index (THI) to safeguard your birds against heat stress.',
    highlights: [
      'Real-time mortality rate & livability % calculations',
      'Environmental Heat Stress & THI risk analysis',
      'Offline-first logging with auto-sync when reconnected',
    ],
    icon: Icons.speed_rounded,
    primaryColor: Color(0xFF104422),
    secondaryColor: Color(0xFF16A34A),
  ),
  OnboardingPillarData(
    badge: 'GROWTH BENCHMARKS & 42-DAY PLAN',
    headline: 'Industry Standard Curves',
    subtitle: 'Cobb 500 & Ross 308 trajectories at your fingertips',
    description:
        'Compare your actual bird weight curves directly against global breed benchmarks. Identify growth lag days early with Average Daily Gain (ADG) velocity and EPEF efficiency metrics.',
    highlights: [
      'Dynamic day-count calendar from hatchery placement',
      'Cumulative FCR vs target breed standard curve',
      'European Production Efficiency Factor (EPEF) scoring',
    ],
    icon: Icons.trending_up_rounded,
    primaryColor: Color(0xFF0F766E),
    secondaryColor: Color(0xFF0284C7),
  ),
  OnboardingPillarData(
    badge: 'CONNECTED INVENTORY & SILOS',
    headline: 'Automated Supply Deductions',
    subtitle: 'Zero manual re-entry — fully synchronized',
    description:
        'Daily feed consumption and healthcare administrations automatically decrement your warehouse bins and medical chests in real-time. Never face sudden stockouts again.',
    highlights: [
      'Auto-deductions when logging daily feeding or health',
      'Minimum reorder threshold & 30-day expiry warnings',
      'PDF & CSV inventory audit reports ready for export',
    ],
    icon: Icons.inventory_2_rounded,
    primaryColor: Color(0xFFB45309),
    secondaryColor: Color(0xFFD97706),
  ),
  OnboardingPillarData(
    badge: 'FARM FINANCIALS & PROFITABILITY',
    headline: 'Live Profit & Cost Tracking',
    subtitle: 'Track every rupee from chick placement to harvest',
    description:
        'Complete financial clarity. Chick purchases, feed expenses, healthcare costs, and bird sales are unified into an accurate Profit & Loss statement with real-time cost-per-kg breakdown.',
    highlights: [
      'Auto-linked expense ledgers from feed and vaccines',
      'Harvest bird sales, live revenue & net profit margins',
      'Monthly operating budget alerts and variance analysis',
    ],
    icon: Icons.account_balance_wallet_rounded,
    primaryColor: Color(0xFF15803D),
    secondaryColor: Color(0xFF059669),
  ),
  OnboardingPillarData(
    badge: 'AI CONSULTANT & OFFLINE POWER',
    headline: '24/7 AI Advisor & 100% Offline',
    subtitle: 'Expert veterinary insights with zero connection dependency',
    description:
        'Consult an intelligent poultry consultant powered by Google Gemini, grounded in your real flock telemetry. Run seamlessly in remote sheds with zero internet dependency.',
    highlights: [
      'Clinical recommendations based on live flock data',
      'Smart Alerts for mortality spikes and heat emergencies',
      '100% offline capability — never lose a single farm record',
    ],
    icon: Icons.psychology_rounded,
    primaryColor: Color(0xFF4338CA),
    secondaryColor: Color(0xFF7C3AED),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.isReplay = false});

  /// If true, this screen is being viewed from Settings/Help as a walkthrough replay,
  /// so finishing simply navigates back instead of redirecting to the initial route.
  final bool isReplay;

  static const String hasSeenOnboardingKey = 'flocksense_has_seen_onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // 1. Mark complete in local SharedPreferences for offline resilience
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen.hasSeenOnboardingKey, true);
    } catch (e) {
      debugPrint('[Onboarding] Error saving local preferences: $e');
    }

    // 2. Mark complete in Firebase Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'hasCompletedOnboarding': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[Onboarding] Error saving Firestore onboarding state: $e');
      }
    }

    if (!mounted) return;

    if (widget.isReplay) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPillar = _pillars[_page];
    final isLast = _page == _pillars.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isReplay
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                tooltip: 'Close Tour',
                onPressed: () => Navigator.pop(context),
              )
            : (_page > 0
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  )
                : null),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: currentPillar.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flutter_dash_rounded,
                    size: 16,
                    color: currentPillar.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FlockSense',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: currentPillar.primaryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!isLast && !widget.isReplay)
            TextButton(
              onPressed: _finish,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page view carousel
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pillars.length,
                itemBuilder: (_, i) => _PillarPageView(pillar: _pillars[i]),
              ),
            ),

            // Bottom control strip
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pillars.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? currentPillar.primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPillar.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLast
                          ? _finish
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast
                                ? (widget.isReplay ? 'Back to App' : "Get Started")
                                : 'Next Pillar',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLast
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
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

class _PillarPageView extends StatelessWidget {
  const _PillarPageView({required this.pillar});
  final OnboardingPillarData pillar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Central Visual Hero Emblem
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [pillar.primaryColor, pillar.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: pillar.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              pillar.icon,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Badge pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: pillar.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: pillar.primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              pillar.badge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: pillar.primaryColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Headline
          Text(
            pillar.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            pillar.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: pillar.primaryColor,
            ),
          ),
          const SizedBox(height: 14),

          // Detailed Paragraph
          Text(
            pillar.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),

          // Highlight Bullets Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: pillar.highlights
                  .map(
                    (highlight) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: pillar.secondaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              highlight,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
