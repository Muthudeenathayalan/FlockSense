import 'package:flutter/material.dart';
import 'package:flock_sense/screens/contact_us_screen.dart';
import 'package:flock_sense/screens/faq_screen.dart';
import 'package:flock_sense/screens/flock_ai_screen.dart';
import 'package:flock_sense/screens/reports_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'More',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore extra tools, reports, AI chat, and support.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _MoreOption(
                    title: 'Flock AI',
                    subtitle: 'Chat with your poultry assistant',
                    icon: Icons.smart_toy,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FlockAiScreen()),
                    ),
                  ),
                  _MoreOption(
                    title: 'Reports',
                    subtitle: 'Generate and download farm reports',
                    icon: Icons.insert_drive_file,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    ),
                  ),
                  _MoreOption(
                    title: 'FAQ',
                    subtitle: 'Frequently asked questions',
                    icon: Icons.help_center,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                  ),
                  _MoreOption(
                    title: 'Contact Us',
                    subtitle: 'Get help from support',
                    icon: Icons.support_agent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
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

class _MoreOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
