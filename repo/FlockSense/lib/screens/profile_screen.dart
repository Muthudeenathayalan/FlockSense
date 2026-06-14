import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName ?? 'Poultry Manager';
    final displayEmail = user.email ?? user.phoneNumber ?? 'No contact info';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.teal.shade50,
                  child: Text(displayName.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.teal)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(displayEmail, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ProfileTile(title: 'Profile details', subtitle: 'Name, contact, farm info', icon: Icons.person, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile details will be available soon')))),
            _ProfileTile(title: 'Subscription', subtitle: 'Premium access and plans', icon: Icons.workspace_premium, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription options coming soon')))),
            _ProfileTile(title: 'Security', subtitle: 'Change password and login settings', icon: Icons.lock, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security settings coming soon')))),
            const SizedBox(height: 24),
            const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ProfileTile(title: 'Theme', subtitle: 'Switch light/dark mode', icon: Icons.color_lens, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme customization coming soon')))),
            _ProfileTile(title: 'Language', subtitle: 'Change app language', icon: Icons.language, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Language support coming soon')))),
            _ProfileTile(title: 'Help center', subtitle: 'Support resources and feedback', icon: Icons.help, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help center coming soon')))),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.indigo.shade50, child: Icon(icon, color: Colors.indigo)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
