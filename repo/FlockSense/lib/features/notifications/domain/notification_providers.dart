import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';

class NotificationFilterState {
  final String searchQuery;
  final NotificationType? typeFilter;
  final NotificationPriority? priorityFilter;
  final String
  statusFilter; // 'all', 'unread', 'read', 'critical', 'reminder', 'ai'
  final String? selectedFarmId;
  final String? selectedBatchId;

  const NotificationFilterState({
    this.searchQuery = '',
    this.typeFilter,
    this.priorityFilter,
    this.statusFilter = 'all',
    this.selectedFarmId,
    this.selectedBatchId,
  });

  NotificationFilterState copyWith({
    String? searchQuery,
    NotificationType? typeFilter,
    NotificationPriority? priorityFilter,
    String? statusFilter,
    String? selectedFarmId,
    String? selectedBatchId,
    bool clearType = false,
    bool clearPriority = false,
  }) {
    return NotificationFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      priorityFilter: clearPriority
          ? null
          : (priorityFilter ?? this.priorityFilter),
      statusFilter: statusFilter ?? this.statusFilter,
      selectedFarmId: selectedFarmId ?? this.selectedFarmId,
      selectedBatchId: selectedBatchId ?? this.selectedBatchId,
    );
  }
}

class NotificationFilterNotifier extends Notifier<NotificationFilterState> {
  @override
  NotificationFilterState build() => const NotificationFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(NotificationType? type) {
    state = state.copyWith(typeFilter: type, clearType: type == null);
  }

  void setPriorityFilter(NotificationPriority? priority) {
    state = state.copyWith(
      priorityFilter: priority,
      clearPriority: priority == null,
    );
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void resetFilters() {
    state = const NotificationFilterState();
  }
}

final notificationFilterProvider =
    NotifierProvider<NotificationFilterNotifier, NotificationFilterState>(
      NotificationFilterNotifier.new,
    );

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  return NotificationFirestoreService.streamNotifications();
});

final remindersStreamProvider = StreamProvider<List<ReminderModel>>((ref) {
  return NotificationFirestoreService.streamReminders();
});

final notificationSettingsProvider = StreamProvider<NotificationSettingsModel>((
  ref,
) {
  return NotificationFirestoreService.streamSettings();
});

class NotificationStatsResult {
  final int unreadCount;
  final int todayAlertsCount;
  final int criticalAlertsCount;
  final int completedRemindersCount;

  const NotificationStatsResult({
    required this.unreadCount,
    required this.todayAlertsCount,
    required this.criticalAlertsCount,
    required this.completedRemindersCount,
  });
}

final notificationStatsProvider = Provider<NotificationStatsResult>((ref) {
  final notifsAsync = ref.watch(notificationsStreamProvider);
  final remindersAsync = ref.watch(remindersStreamProvider);

  final notifications = notifsAsync.asData?.value ?? [];
  final reminders = remindersAsync.asData?.value ?? [];

  final now = DateTime.now();

  final unreadCount = notifications
      .where((n) => n.status == NotificationStatus.unread)
      .length;
  final todayAlertsCount = notifications
      .where(
        (n) =>
            n.createdAt.year == now.year &&
            n.createdAt.month == now.month &&
            n.createdAt.day == now.day,
      )
      .length;
  final criticalAlertsCount = notifications
      .where((n) => n.priority == NotificationPriority.critical)
      .length;
  final completedRemindersCount = reminders.where((r) => r.isCompleted).length;

  return NotificationStatsResult(
    unreadCount: unreadCount,
    todayAlertsCount: todayAlertsCount,
    criticalAlertsCount: criticalAlertsCount,
    completedRemindersCount: completedRemindersCount,
  );
});
