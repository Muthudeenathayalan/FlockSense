import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final userStateService = ref.read(userStateServiceProvider);
    await userStateService.signOut();

    if (context.mounted) {
      // AuthWrapper will automatically redirect to login via userStateStreamProvider
      Navigator.pushReplacementNamed(context, AppRoutes.initial);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Farmer';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $displayName',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Manage your profile, subscriptions, and settings.'),
              const SizedBox(height: 24),
              _buildOption(context, Icons.person, 'My Profile'),
              _buildOption(context, Icons.card_membership,
                  'Membership Details'),
              _buildOption(context, Icons.shopping_cart, 'Buy Subscription'),
              _buildOption(context, Icons.language, 'Change Language'),
              _buildOption(context, Icons.lock, 'Change Password'),
              _buildOption(context, Icons.chat, 'Join WhatsApp Group'),
              _buildOption(context, Icons.help_outline, 'FAQ'),
              _buildOption(context, Icons.support_agent, 'Contact Us'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _logout(context, ref),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade700,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title coming soon')),
            );
          },
        ),
        const Divider(),
      ],
    );
  }
}
