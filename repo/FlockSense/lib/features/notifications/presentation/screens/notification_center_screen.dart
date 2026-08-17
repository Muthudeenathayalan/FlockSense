import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';
import 'package:flock_sense/features/notifications/data/services/smart_alert_evaluator.dart';
import 'package:flock_sense/features/notifications/domain/notification_providers.dart';
import 'package:flock_sense/features/notifications/presentation/widgets/notification_card.dart';
import 'package:flock_sense/features/notifications/presentation/widgets/notification_kpi_header.dart';
import 'package:flock_sense/features/notifications/presentation/widgets/notification_settings_dialog.dart';
import 'package:flock_sense/features/notifications/presentation/widgets/reminder_form_dialog.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Evaluate smart alerts on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartAlertEvaluator.evaluateSmartAlerts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateReminder() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ReminderFormDialog(),
    );
    if (result == true) {
      ref.invalidate(remindersStreamProvider);
    }
  }

  void _openSettingsDialog() async {
    final settingsAsync = ref.read(notificationSettingsProvider);
    final settings = settingsAsync.asData?.value ?? const NotificationSettingsModel();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => NotificationSettingsDialog(currentSettings: settings),
    );
    if (result == true) {
      ref.invalidate(notificationSettingsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(notificationFilterProvider);
    final filterNotifier = ref.read(notificationFilterProvider.notifier);
    final stats = ref.watch(notificationStatsProvider);
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final remindersAsync = ref.watch(remindersStreamProvider);

    final notifications = notifsAsync.asData?.value ?? [];
    final reminders = remindersAsync.asData?.value ?? [];

    final searchQuery = filter.searchQuery.toLowerCase();

    // Filter Notifications
    final filteredNotifs = notifications.where((n) {
      if (filter.statusFilter == 'unread' && n.status != NotificationStatus.unread) return false;
      if (filter.statusFilter == 'critical' && n.priority != NotificationPriority.critical) return false;
      if (filter.statusFilter == 'ai' && !n.isAiAlert) return false;
      if (filter.typeFilter != null && n.type != filter.typeFilter) return false;

      if (searchQuery.isNotEmpty) {
        final matchesTitle = n.title.toLowerCase().contains(searchQuery);
        final matchesBody = n.body.toLowerCase().contains(searchQuery);
        return matchesTitle || matchesBody;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All as Read',
            onPressed: () async {
              await NotificationFirestoreService.markAllAsRead();
              ref.invalidate(notificationsStreamProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification Settings',
            onPressed: _openSettingsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1B5E20),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1B5E20),
          tabs: const [
            Tab(text: 'Alerts'),
            Tab(text: 'Reminders'),
            Tab(text: 'History'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Create Reminder'),
        onPressed: _openCreateReminder,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // KPI Header Cards
                NotificationKpiHeader(
                  unreadCount: stats.unreadCount,
                  todayAlertsCount: stats.todayAlertsCount,
                  criticalAlertsCount: stats.criticalAlertsCount,
                  completedRemindersCount: stats.completedRemindersCount,
                ),
                const SizedBox(height: 10),

                // Search & Filter Toolbar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => filterNotifier.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search alerts & reminders...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: filter.statusFilter == 'all' && filter.typeFilter == null,
                        onSelected: (_) {
                          filterNotifier.setStatusFilter('all');
                          filterNotifier.setTypeFilter(null);
                        },
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text('Unread'),
                        selected: filter.statusFilter == 'unread',
                        onSelected: (_) => filterNotifier.setStatusFilter('unread'),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text('Critical'),
                        selected: filter.statusFilter == 'critical',
                        onSelected: (_) => filterNotifier.setStatusFilter('critical'),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text('AI Insights'),
                        selected: filter.statusFilter == 'ai',
                        onSelected: (_) => filterNotifier.setStatusFilter('ai'),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text('Feed'),
                        selected: filter.typeFilter == NotificationType.feed,
                        onSelected: (_) => filterNotifier.setTypeFilter(NotificationType.feed),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text('Medicine'),
                        selected: filter.typeFilter == NotificationType.medicine,
                        onSelected: (_) => filterNotifier.setTypeFilter(NotificationType.medicine),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text('Finance'),
                        selected: filter.typeFilter == NotificationType.finance,
                        onSelected: (_) => filterNotifier.setTypeFilter(NotificationType.finance),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Alerts
                RefreshIndicator(
                  onRefresh: () async {
                    await SmartAlertEvaluator.evaluateSmartAlerts();
                    ref.invalidate(notificationsStreamProvider);
                  },
                  child: filteredNotifs.isEmpty
                      ? const Center(child: Text('No active alerts matching filter.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filteredNotifs.length,
                          itemBuilder: (ctx, index) => NotificationCard(notification: filteredNotifs[index]),
                        ),
                ),

                // Tab 2: Reminders
                RefreshIndicator(
                  onRefresh: () async => ref.invalidate(remindersStreamProvider),
                  child: reminders.isEmpty
                      ? const Center(child: Text('No custom reminders scheduled.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: reminders.length,
                          itemBuilder: (ctx, index) {
                            final r = reminders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                value: r.isCompleted,
                                title: Text(r.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: r.isCompleted ? TextDecoration.lineThrough : null)),
                                subtitle: Text('${r.description}\nDue: ${DateFormat('dd MMM yyyy').format(r.date)} at ${r.time} • Repeat: ${r.repeat.name.toUpperCase()}', style: const TextStyle(fontSize: 10)),
                                secondary: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () async {
                                    await NotificationFirestoreService.deleteReminder(r.id);
                                    ref.invalidate(remindersStreamProvider);
                                  },
                                ),
                                onChanged: (_) async {
                                  await NotificationFirestoreService.toggleReminderCompletion(r.id);
                                  ref.invalidate(remindersStreamProvider);
                                },
                              ),
                            );
                          },
                        ),
                ),

                // Tab 3: History & Archive
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text('ARCHIVED ALERTS HISTORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 8),
                    ...notifications.where((n) => n.status == NotificationStatus.archived).map((n) => NotificationCard(notification: n)),
                    if (!notifications.any((n) => n.status == NotificationStatus.archived))
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No archived notification history.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
