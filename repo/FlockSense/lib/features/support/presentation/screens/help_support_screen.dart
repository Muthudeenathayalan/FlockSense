import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/profile/presentation/screens/feedback_screen.dart';
import 'package:flock_sense/features/onboarding/presentation/screens/onboarding_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    _FaqItem(
      question: 'How is FCR (Feed Conversion Ratio) calculated?',
      answer:
          'FCR is calculated as: Cumulative Total Feed Consumed (kg) divided by Total Live Biomass (kg). Total Live Biomass = (Current Live Birds * Average Body Weight in grams) / 1000. A lower FCR indicates superior feed efficiency.',
    ),
    _FaqItem(
      question: 'Can I record farm data while offline?',
      answer:
          'Yes! FlockSense automatically saves daily entries, feed logs, and medicine records to local cache when internet is unavailable. Once you reconnect, all pending operations sync automatically to your Firestore cloud database.',
    ),
    _FaqItem(
      question: 'How do I add a new batch or shed?',
      answer:
          'Go to the Explore/More tab, choose "Farms & Sheds", tap your farm, then tap "Add Shed" or "Place Batch". You can specify chick placement date, male/female counts, breed (e.g. Cobb 500, Ross 308), and hatch details.',
    ),
    _FaqItem(
      question: 'How do I export PDF and Excel reports for integrators?',
      answer:
          'Navigate to the Reports Center from the bottom navigation or Explore screen. Select your batch and date range, then tap "Export PDF" or "Export Excel" to save, print, or share via WhatsApp/Email.',
    ),
    _FaqItem(
      question: 'How do I consult the AI Advisor?',
      answer:
          'Tap "AI Advisor" on the More screen. The advisor automatically ingests your active farm telemetry (mortality %, FCR, age, and temperature) to give personalized management suggestions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Assistance?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Our poultry management support team is available to assist you.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send Message'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support helpline: +91 98765 43210 (Mon-Sat 9AM-6PM)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                      label: const Text('Call Us', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App Tour Replay Card
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OnboardingScreen(isReplay: true),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.explore_outlined,
                      color: Color(0xFF0F766E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore FlockSense Pillars',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Revisit the 5-pillar tour anytime',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ..._faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ExpansionTile(
                  title: Text(
                    faq.question,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          Center(
            child: Column(
              children: const [
                Text(
                  'FlockSense Poultry Farm Management',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                SizedBox(height: 2),
                Text(
                  'Version 1.1.0+2 • Powered by Google Flutter',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
