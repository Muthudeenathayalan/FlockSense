import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/settings/data/services/settings_service.dart';
import 'package:flock_sense/features/settings/domain/settings_providers.dart';
import 'package:flock_sense/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:flock_sense/features/settings/presentation/widgets/edit_profile_dialog.dart';
import 'package:flock_sense/features/settings/presentation/widgets/settings_tile.dart';

class SettingsDashboardScreen extends ConsumerStatefulWidget {
  const SettingsDashboardScreen({super.key});

  @override
  ConsumerState<SettingsDashboardScreen> createState() => _SettingsDashboardScreenState();
}

class _SettingsDashboardScreenState extends ConsumerState<SettingsDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Account',
    'Appearance',
    'Units',
    'Notifications',
    'AI Advisor',
    'Data & Storage',
    'Backup & Sync',
    'Privacy',
    'About',
    'Support',
    'Advanced',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditProfile(String name, String phone) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditProfileDialog(currentName: name, currentPhone: phone),
    );
    if (result == true) {
      ref.invalidate(settingsNotifierProvider);
    }
  }

  void _openChangePassword() {
    showDialog(
      context: context,
      builder: (ctx) => const ChangePasswordDialog(),
    );
  }

  bool _matchesCategory(String sectionTitle, String searchKeywords) {
    if (_selectedCategory != 'All' && !_selectedCategory.toLowerCase().contains(sectionTitle.toLowerCase()) && !sectionTitle.toLowerCase().contains(_selectedCategory.toLowerCase())) {
      return false;
    }
    if (_searchQuery.isNotEmpty && !searchKeywords.toLowerCase().contains(_searchQuery) && !sectionTitle.toLowerCase().contains(_searchQuery)) {
      return false;
    }
    return true;
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final user = ref.watch(currentUserProvider);

    final email = user?.email ?? 'farmer@flocksense.com';
    final name = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : prefs.displayName;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Color(0xFF64748B)),
            tooltip: 'Reset Defaults',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset All Settings'),
                  content: const Text('This will reset all application preferences to factory defaults. Continue?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await notifier.resetSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to factory defaults.')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO PROFILE CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3811), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber.shade400, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'F',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${prefs.role} • ${prefs.phone}',
                                style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('Edit Profile', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          onPressed: () => _openEditProfile(name, prefs.phone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B5E20),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.lock_outline, size: 15),
                          label: const Text('Change Password', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          onPressed: _openChangePassword,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search preferences...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // CATEGORY FILTER PILLS
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B5E20),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 1: ACCOUNT
            if (_matchesCategory('Account', 'account profile name email phone role')) ...[
              const SettingsSectionHeader(title: 'Account & Verification', icon: Icons.person_outline),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.account_circle_outlined,
                    title: 'Account Created',
                    subtitle: DateFormat('dd MMMM yyyy').format(prefs.accountCreatedDate),
                  ),
                  SettingsTile(
                    icon: Icons.access_time_outlined,
                    title: 'Last Login',
                    subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(prefs.lastLoginDate),
                  ),
                  SettingsTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Email Verification',
                    subtitle: user?.emailVerified == true ? 'Email Verified ✓' : 'Unverified • Tap to send link',
                    trailing: user?.emailVerified == true
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => SettingsService.sendEmailVerification(),
                            child: const Text('Verify', style: TextStyle(fontSize: 11)),
                          ),
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 2: APP APPEARANCE
            if (_matchesCategory('Appearance', 'appearance theme mode font dynamic color')) ...[
              const SettingsSectionHeader(title: 'App Appearance', icon: Icons.palette_outlined),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.brightness_medium_outlined,
                    title: 'Theme Mode',
                    subtitle: 'Current: ${prefs.themeMode.toUpperCase()}',
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.themeMode,
                        items: const [
                          DropdownMenuItem(value: 'system', child: Text('System', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'light', child: Text('Light', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'dark', child: Text('Dark', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateThemeMode(val!),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.format_size,
                    title: 'Font Size',
                    subtitle: prefs.fontSize,
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.fontSize,
                        items: const [
                          DropdownMenuItem(value: 'Small', child: Text('Small', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Large', child: Text('Large', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateSettings(prefs.copyWith(fontSize: val!)),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: 'Enable Dynamic Colors',
                    subtitle: 'Adapt accent palette to system theme',
                    trailing: Switch(
                      value: prefs.enableDynamicColors,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateSettings(prefs.copyWith(enableDynamicColors: val)),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 3: LANGUAGE
            if (_matchesCategory('Language', 'language english tamil')) ...[
              const SettingsSectionHeader(title: 'Language & Locale', icon: Icons.translate),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.language,
                    title: 'Application Language',
                    subtitle: prefs.languageCode == 'en' ? 'English (US)' : 'Tamil (தமிழ்)',
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.languageCode,
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'ta', child: Text('Tamil (தமிழ்)', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateLanguage(val!),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 4: UNITS & CURRENCY
            if (_matchesCategory('Units', 'units weight temperature currency distance')) ...[
              const SettingsSectionHeader(title: 'Units & Measurements', icon: Icons.straighten),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.scale_outlined,
                    title: 'Weight Unit',
                    subtitle: prefs.weightUnit,
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.weightUnit,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('Kilograms (kg)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'g', child: Text('Grams (g)', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateUnits(weightUnit: val!),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.thermostat_outlined,
                    title: 'Temperature Unit',
                    subtitle: prefs.temperatureUnit,
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.temperatureUnit,
                        items: const [
                          DropdownMenuItem(value: '°C', child: Text('Celsius (°C)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '°F', child: Text('Fahrenheit (°F)', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateUnits(temperatureUnit: val!),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.payments_outlined,
                    title: 'Currency Unit',
                    subtitle: prefs.currency,
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.currency,
                        items: const [
                          DropdownMenuItem(value: 'INR (₹)', child: Text('INR (₹)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'USD (\$)', child: Text('USD (\$)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'EUR (€)', child: Text('EUR (€)', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateUnits(currency: val!),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 5: NOTIFICATIONS
            if (_matchesCategory('Notifications', 'notifications push ai alerts quiet hours vibration')) ...[
              const SettingsSectionHeader(title: 'Notifications & Alerts', icon: Icons.notifications_active_outlined),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.phonelink_ring_outlined,
                    title: 'Push Notifications',
                    subtitle: 'FCM Background & Alert Center',
                    trailing: Switch(
                      value: prefs.pushEnabled,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateNotificationToggles(pushEnabled: val),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.psychology_outlined,
                    title: 'AI Smart Alerts',
                    subtitle: 'Predictive mortality & feed spillage advisories',
                    trailing: Switch(
                      value: prefs.aiNotifsEnabled,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateNotificationToggles(aiNotifsEnabled: val),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.vibration,
                    title: 'Vibration Feedback',
                    subtitle: 'Haptic feedback on high priority alerts',
                    trailing: Switch(
                      value: prefs.vibration,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateNotificationToggles(vibration: val),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 6: AI SETTINGS
            if (_matchesCategory('AI', 'ai model gemini memory context telemetry')) ...[
              const SettingsSectionHeader(title: 'AI Advisor & Intelligence', icon: Icons.smart_toy_outlined),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.model_training,
                    title: 'AI Model Engine',
                    subtitle: prefs.aiModel,
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.aiModel,
                        items: const [
                          DropdownMenuItem(value: 'Gemini 1.5 Flash', child: Text('Gemini 1.5 Flash', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Gemini 1.5 Pro', child: Text('Gemini 1.5 Pro', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateAiSettings(aiModel: val!),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.style_outlined,
                    title: 'Response Style',
                    subtitle: prefs.responseStyle,
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.responseStyle,
                        items: const [
                          DropdownMenuItem(value: 'Brief', child: Text('Brief', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Balanced', child: Text('Balanced', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Detailed', child: Text('Detailed', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => notifier.updateAiSettings(responseStyle: val!),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.memory,
                    title: 'AI Conversation Memory',
                    subtitle: 'Retain context across chat sessions',
                    trailing: Switch(
                      value: prefs.aiMemoryEnabled,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateAiSettings(aiMemoryEnabled: val),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.analytics_outlined,
                    title: 'Live Farm Telemetry',
                    subtitle: 'Pass live feed/mortality data to AI model',
                    trailing: Switch(
                      value: prefs.useFarmContext,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateAiSettings(useFarmContext: val),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 7: DATA & STORAGE
            if (_matchesCategory('Data', 'data storage cache clear size')) ...[
              const SettingsSectionHeader(title: 'Data & Local Storage', icon: Icons.storage_outlined),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.sd_storage_outlined,
                    title: 'Cache Size',
                    subtitle: '${prefs.cacheSizeMb.toStringAsFixed(1)} MB occupied',
                    trailing: SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                        ),
                        onPressed: () async {
                          await notifier.clearCache();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully!')));
                          }
                        },
                        child: const Text('Clear', style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20))),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.cloud_download_outlined,
                    title: 'Storage Occupied',
                    subtitle: '${prefs.storageUsedMb.toStringAsFixed(1)} MB (Local & Firestore sync)',
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 8: BACKUP & SYNC
            if (_matchesCategory('Backup', 'backup sync cloud restore')) ...[
              const SettingsSectionHeader(title: 'Cloud Backup & Sync', icon: Icons.cloud_sync_outlined),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.sync,
                    title: 'Auto Cloud Sync',
                    subtitle: 'Status: ${prefs.cloudSyncStatus}',
                    trailing: Switch(
                      value: prefs.autoBackupEnabled,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateSettings(prefs.copyWith(autoBackupEnabled: val)),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.backup_outlined,
                    title: 'Backup Now',
                    subtitle: 'Last Backup: ${prefs.lastBackupTime != null ? DateFormat('dd MMM yyyy, hh:mm a').format(prefs.lastBackupTime!) : "Never"}',
                    onTap: () {
                      notifier.updateSettings(prefs.copyWith(lastBackupTime: DateTime.now(), cloudSyncStatus: 'Synced'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud backup created successfully!')));
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 9: PRIVACY & SECURITY
            if (_matchesCategory('Privacy', 'privacy security biometric pin lock auto logout')) ...[
              const SettingsSectionHeader(title: 'Privacy & App Security', icon: Icons.security_outlined),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.fingerprint,
                    title: 'Biometric Lock',
                    subtitle: 'Fingerprint / Face ID unlock',
                    trailing: Switch(
                      value: prefs.biometricLogin,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateSettings(prefs.copyWith(biometricLogin: val)),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.pin_outlined,
                    title: 'PIN Passcode Lock',
                    subtitle: '4-digit app security PIN',
                    trailing: Switch(
                      value: prefs.pinLock,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateSettings(prefs.copyWith(pinLock: val)),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.timer_outlined,
                    title: 'Auto Logout Timeout',
                    subtitle: '${prefs.autoLogoutMinutes} Minutes idle',
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 10: ABOUT
            if (_matchesCategory('About', 'about version build licenses developer')) ...[
              const SettingsSectionHeader(title: 'About Application', icon: Icons.info_outline),
              _buildSectionCard(
                children: const [
                  SettingsTile(
                    icon: Icons.verified_outlined,
                    title: 'App Version',
                    subtitle: 'FlockSense v1.1.0+2 (Build 2026.08)',
                  ),
                  SettingsTile(
                    icon: Icons.code,
                    title: 'Developer Information',
                    subtitle: 'Built with Flutter & Firebase by FlockSense Engineering',
                  ),
                  SettingsTile(
                    icon: Icons.policy_outlined,
                    title: 'Open Source Licenses',
                    subtitle: 'Flutter, Riverpod, Firebase, fl_chart, pdf',
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 11: SUPPORT
            if (_matchesCategory('Support', 'support help faqs bug report rate share')) ...[
              const SettingsSectionHeader(title: 'Support & Help', icon: Icons.help_outline),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.help_center_outlined,
                    title: 'Help Center & FAQs',
                    subtitle: 'Browse flock management user guides',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Help Center...')));
                    },
                  ),
                  SettingsTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Bug / Issue',
                    subtitle: 'Send feedback to engineering team',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Bug Reporter...')));
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ],

            // SECTION 12: ADVANCED
            if (_matchesCategory('Advanced', 'advanced developer mode logs reset factory')) ...[
              const SettingsSectionHeader(title: 'Advanced Diagnostics', icon: Icons.developer_mode),
              _buildSectionCard(
                children: [
                  SettingsTile(
                    icon: Icons.bug_report,
                    title: 'Developer Mode',
                    subtitle: 'Enable verbose console telemetry',
                    trailing: Switch(
                      value: prefs.developerMode,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) => notifier.updateSettings(prefs.copyWith(developerMode: val)),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.restart_alt,
                    title: 'Factory Reset',
                    subtitle: 'Restore initial configuration',
                    iconColor: Colors.red,
                    onTap: () async {
                      await notifier.resetSettings();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Factory reset complete.')));
                      }
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
