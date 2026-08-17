import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flock_sense/features/calendar/presentation/screens/calendar_event_form_screen.dart';
import 'package:flock_sense/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:flock_sense/features/calendar/presentation/widgets/event_card.dart';
import 'package:flock_sense/features/calendar/presentation/widgets/event_details_sheet.dart';
import 'package:flock_sense/features/calendar/presentation/widgets/todays_summary_card.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

class CalendarDashboardScreen extends ConsumerWidget {
  const CalendarDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(calendarStreamProvider);
    final filteredEvents = ref.watch(filteredCalendarEventsProvider);
    final stats = ref.watch(calendarStatsProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedFilter = ref.watch(calendarEventFilterProvider);
    final searchQuery = ref.watch(calendarSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Calendar & Reminders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            tooltip: 'Sync Telemetry Reminders',
            onPressed: () => _syncTelemetryReminders(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            tooltip: 'Add Event',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalendarEventFormScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CalendarEventFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text(
          'Add Reminder',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: calendarAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading your farm schedule...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => _buildErrorState(context, ref, error),
        data: (allRawEvents) => Column(
          children: [
            // Top Summary KPI Strip
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: TodaysSummaryCard(stats: stats),
            ),
            const Divider(height: 1, color: AppColors.border),

            // View Mode Selector & Search Input Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // View Mode Segmented Pill Buttons
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _viewModeBtn(ref, 'Month', CalendarViewMode.month, viewMode),
                              _viewModeBtn(ref, 'Week', CalendarViewMode.week, viewMode),
                              _viewModeBtn(ref, 'Day', CalendarViewMode.day, viewMode),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Smart Sync Button
                      InkWell(
                        onTap: () => _syncTelemetryReminders(context, ref),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Auto Sync',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Field
                  TextField(
                    onChanged: (val) {
                      ref.read(calendarSearchQueryProvider.notifier).setQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search events, vaccines, harvest...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textHint),
                              onPressed: () {
                                ref.read(calendarSearchQueryProvider.notifier).setQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceSoft.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Category & Date Filter Chips Horizontal Scroll
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip(ref, 'All', selectedFilter == 'All'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Today', selectedFilter == 'Today'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Tomorrow', selectedFilter == 'Tomorrow'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'This Week', selectedFilter == 'This Week'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'This Month', selectedFilter == 'This Month'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Vaccination', selectedFilter == 'Vaccination'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Medicine', selectedFilter == 'Medicine'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Harvest', selectedFilter == 'Harvest'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Cleaning', selectedFilter == 'Cleaning'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Inventory', selectedFilter == 'Inventory'),
                    const SizedBox(width: 6),
                    _filterChip(ref, 'Completed', selectedFilter == 'Completed'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Main Content Area: Calendar View + Event List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(calendarStreamProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 85),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TableCalendar View Widget
                      CalendarViewWidget(events: allRawEvents),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Scheduled Events (${filteredEvents.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              selectedFilter,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (filteredEvents.isEmpty)
                        _buildEmptyState(context)
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            return EventCard(
                              event: event,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => EventDetailsSheet(event: event),
                                );
                              },
                              onToggleComplete: (val) async {
                                final service = ref.read(calendarServiceProvider);
                                await service.markCompleted(
                                  uid: event.ownerId,
                                  farmId: event.farmId,
                                  eventId: event.id,
                                  isCompleted: val ?? false,
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewModeBtn(WidgetRef ref, String label, CalendarViewMode mode, CalendarViewMode currentMode) {
    final selected = mode == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(calendarViewModeProvider.notifier).setMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    const BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String label, bool selected) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        ref.read(calendarEventFilterProvider.notifier).setFilter(label);
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceSoft,
      elevation: selected ? 2 : 0,
      pressElevation: 1,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Future<void> _syncTelemetryReminders(BuildContext context, WidgetRef ref) async {
    try {
      final user = ref.read(authStateProvider).value;
      final activeFarmId = ref.read(activeFarmIdProvider).value;

      if (user == null) return;

      final service = ref.read(calendarServiceProvider);
      final created = await service.generateAutoEventsFromTelemetry(
        uid: user.uid,
        farmId: activeFarmId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              created > 0
                  ? 'Synced telemetry! Generated $created smart reminders.'
                  : 'Telemetry in sync. No new reminders generated.',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync telemetry reminders: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No events scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Schedule vaccinations, feed deliveries, harvest dates, or custom farm reminders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarEventFormScreen()),
              );
            },
            icon: const Icon(Icons.add_alert_rounded, size: 18),
            label: const Text('Create First Reminder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load calendar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().contains('permission-denied')
                  ? 'Permission denied. Check Firestore security rules.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _syncTelemetryReminders(context, ref);
                ref.invalidate(calendarStreamProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry & Sync Telemetry'),
            ),
          ],
        ),
      ),
    );
  }
}
