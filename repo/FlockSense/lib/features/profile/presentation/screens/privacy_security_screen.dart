import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 36, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Your Farm Data Is Protected',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'FlockSense uses end-to-end user isolation, encrypted storage, and offline-first local vaults.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            icon: Icons.lock_outline,
            title: 'Data Ownership & Confidentiality',
            body:
                'All flock metrics, bird weights, feed quantities, financial transactions, and farm locations belong exclusively to you. Your farm data is never sold, shared with competitors, or used for advertising.',
          ),
          const SizedBox(height: 16),

          _buildSection(
            icon: Icons.cloud_done_outlined,
            title: 'Cloud Encryption Standards',
            body:
                'Data synced to Google Cloud Firestore is protected by TLS 1.3 in transit and AES-256 encryption at rest. Every read and write request is strictly validated against Firebase Security Rules tied to your verified UID.',
          ),
          const SizedBox(height: 16),

          _buildSection(
            icon: Icons.sd_storage_outlined,
            title: 'Offline Local Storage',
            body:
                'Offline data cached in Hive boxes is sandboxed within your device OS storage space. No unauthorized third-party apps can access your local logs.',
          ),
          const SizedBox(height: 16),

          _buildSection(
            icon: Icons.fingerprint,
            title: 'Authentication & Credential Protection',
            body:
                'Passwords and Phone OTPs are processed directly by Firebase Authentication using cryptographic scrypt hashes. API keys and credentials are never stored in unencrypted client plaintext.',
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Rights & Export',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You can export your complete records as Excel or PDF at any time via the Reports Center. To request full deletion of your cloud account and all subcollections, contact our privacy officer at support@flocksense.com.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
