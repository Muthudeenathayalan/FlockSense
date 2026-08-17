import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/calendar/data/calendar_service.dart';
import 'package:flock_sense/features/calendar/domain/calendar_event_model.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

enum CalendarViewMode { month, week, day }

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

class CalendarViewModeNotifier extends Notifier<CalendarViewMode> {
  @override
  CalendarViewMode build() => CalendarViewMode.month;
  void setMode(CalendarViewMode mode) => state = mode;
}

final calendarViewModeProvider =
    NotifierProvider<CalendarViewModeNotifier, CalendarViewMode>(CalendarViewModeNotifier.new);

class CalendarSelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void setDate(DateTime date) => state = date;
}

final calendarSelectedDateProvider =
    NotifierProvider<CalendarSelectedDateNotifier, DateTime>(CalendarSelectedDateNotifier.new);

class CalendarSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final calendarSearchQueryProvider =
    NotifierProvider<CalendarSearchQueryNotifier, String>(CalendarSearchQueryNotifier.new);

class CalendarEventFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setFilter(String filter) => state = filter;
}

final calendarEventFilterProvider =
    NotifierProvider<CalendarEventFilterNotifier, String>(CalendarEventFilterNotifier.new);

class CalendarSortNotifier extends Notifier<String> {
  @override
  String build() => 'Date';
  void setSort(String sort) => state = sort;
}

final calendarSortProvider =
    NotifierProvider<CalendarSortNotifier, String>(CalendarSortNotifier.new);

final calendarStreamProvider = StreamProvider.autoDispose<List<CalendarEventModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final activeFarmId = ref.watch(activeFarmIdProvider).value;
  final service = ref.watch(calendarServiceProvider);

  final uid = authState.value?.uid ?? 'guest_user';
  return service.watchCalendarEvents(uid: uid, farmId: activeFarmId);
});

final filteredCalendarEventsProvider = Provider.autoDispose<List<CalendarEventModel>>((ref) {
  final events = ref.watch(calendarStreamProvider).value ?? [];
  final selectedDate = ref.watch(calendarSelectedDateProvider);
  final query = ref.watch(calendarSearchQueryProvider).toLowerCase().trim();
  final filter = ref.watch(calendarEventFilterProvider);
  final sort = ref.watch(calendarSortProvider);
  final viewMode = ref.watch(calendarViewModeProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));
  final weekEnd = todayStart.add(const Duration(days: 7));

  var result = events.where((e) {
    // Search matching
    final matchesQuery = query.isEmpty ||
        e.title.toLowerCase().contains(query) ||
        e.eventType.toLowerCase().contains(query) ||
        (e.description?.toLowerCase().contains(query) ?? false);

    if (!matchesQuery) return false;

    // View mode date filtering
    if (viewMode == CalendarViewMode.day) {
      final isSameDay = e.eventDate.year == selectedDate.year &&
          e.eventDate.month == selectedDate.month &&
          e.eventDate.day == selectedDate.day;
      if (!isSameDay) return false;
    }

    // Category / Date Filter matching
    switch (filter) {
      case 'Today':
        return e.eventDate.year == todayStart.year &&
            e.eventDate.month == todayStart.month &&
            e.eventDate.day == todayStart.day;
      case 'Tomorrow':
        return e.eventDate.year == tomorrowStart.year &&
            e.eventDate.month == tomorrowStart.month &&
            e.eventDate.day == tomorrowStart.day;
      case 'This Week':
        return e.eventDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            e.eventDate.isBefore(weekEnd);
      case 'This Month':
        return e.eventDate.year == now.year && e.eventDate.month == now.month;
      case 'Completed':
        return e.isCompleted;
      case 'All':
        return true;
      default:
        return e.eventType.toLowerCase() == filter.toLowerCase();
    }
  }).toList();

  // Sorting
  switch (sort) {
    case 'Priority':
      final priorityWeight = {'urgent': 4, 'high': 3, 'medium': 2, 'low': 1};
      result.sort((a, b) => (priorityWeight[b.priority.toLowerCase()] ?? 0)
          .compareTo(priorityWeight[a.priority.toLowerCase()] ?? 0));
      break;
    case 'Date':
    default:
      result.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      break;
  }

  return result;
});

class CalendarStats {
  final int todaysEvents;
  final int completedEvents;
  final int pendingEvents;
  final int overdueEvents;
  final int upcomingThisWeek;

  const CalendarStats({
    required this.todaysEvents,
    required this.completedEvents,
    required this.pendingEvents,
    required this.overdueEvents,
    required this.upcomingThisWeek,
  });

  static const empty = CalendarStats(
    todaysEvents: 0,
    completedEvents: 0,
    pendingEvents: 0,
    overdueEvents: 0,
    upcomingThisWeek: 0,
  );
}

final calendarStatsProvider = Provider.autoDispose<CalendarStats>((ref) {
  final events = ref.watch(calendarStreamProvider).value ?? [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekEnd = todayStart.add(const Duration(days: 7));

  int today = 0;
  int completed = 0;
  int pending = 0;
  int overdue = 0;
  int upcomingWeek = 0;

  for (final e in events) {
    if (e.isCompleted) {
      completed++;
    } else {
      pending++;
      if (e.isOverdue) overdue++;
    }

    if (e.eventDate.year == todayStart.year &&
        e.eventDate.month == todayStart.month &&
        e.eventDate.day == todayStart.day) {
      today++;
    }

    if (!e.isCompleted &&
        e.eventDate.isAfter(todayStart) &&
        e.eventDate.isBefore(weekEnd)) {
      upcomingWeek++;
    }
  }

  return CalendarStats(
    todaysEvents: today,
    completedEvents: completed,
    pendingEvents: pending,
    overdueEvents: overdue,
    upcomingThisWeek: upcomingWeek,
  );
});
