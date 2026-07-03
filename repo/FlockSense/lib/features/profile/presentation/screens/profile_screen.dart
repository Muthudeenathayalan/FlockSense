import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/app_settings_screen.dart';
import 'package:flock_sense/features/support/presentation/screens/help_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // FIX — LOGOUT: the previous version called userStateService.signOut()
  // then Navigator.pushReplacementNamed(AppRoutes.initial). If signOut()
  // threw (e.g. no provider registered, or a race with the auth stream),
  // the error surfaced as "An error occurred" on screen. Now we call
  // FirebaseAuth directly (the ground-truth source) and navigate by
  // removing ALL routes so there is no back-stack to return to.
  Future<void> _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (ctx.mounted) {
        // Remove every route and land on AuthWrapper which will show LoginScreen.
        Navigator.pushNamedAndRemoveUntil(ctx, AppRoutes.initial, (_) => false);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Sign out failed: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final name  = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Farmer';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Premium profile header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                  ]),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account section
                _sectionLabel('Account'),
                const SizedBox(height: 8),
                _menuCard([
                  _menuTile(context, Icons.person_outline, 'Edit profile', 'Update your name and details', Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  }),
                  _divider(),
                  _menuTile(context, Icons.lock_outline, 'Change password', 'Update your login password', Colors.orange, () {
                    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Change password'), content: const Text('Password change coming soon'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
                  }),
                  _divider(),
                  _menuTile(context, Icons.notifications_outlined, 'Notifications', 'Manage alert preferences', Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
                  }),
                ]),

                const SizedBox(height: 20),
                _sectionLabel('App'),
                const SizedBox(height: 8),
                _menuCard([
                  _menuTile(context, Icons.language_outlined, 'Language', 'English (default)', Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
                  }),
                  _divider(),
                  _menuTile(context, Icons.help_outline, 'Help & FAQ', 'Get answers and support', Colors.indigo, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                  }),
                  _divider(),
                  _menuTile(context, Icons.info_outline, 'About FlockSense', 'Version 1.0.0', Colors.grey, () {
                    showAboutDialog(context: context, applicationName: 'FlockSense', applicationVersion: '1.0.0', children: [const Text('FlockSense helps you run small commercial poultry farms efficiently.')]);
                  }),
                ]),

                const SizedBox(height: 28),
                // Logout button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.red.shade200),
                    boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: ListTile(
                    onTap: () => _logout(context),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 20),
                    ),
                    title: Text('Sign out', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 15)),
                    subtitle: Text('You can sign back in at any time', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                    trailing: Icon(Icons.chevron_right, color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 1.2)),
      );

  Widget _divider() => const Divider(height: 1, indent: 62, color: AppColors.divider);

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuTile(BuildContext ctx, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        onTap();
      },
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
