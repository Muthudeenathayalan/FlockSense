import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/calendar/domain/calendar_event_model.dart';
import 'package:flock_sense/features/calendar/presentation/providers/calendar_providers.dart';

class CalendarViewWidget extends ConsumerWidget {
  const CalendarViewWidget({super.key, required this.events});

  final List<CalendarEventModel> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final viewMode = ref.watch(calendarViewModeProvider);

    CalendarFormat format;
    switch (viewMode) {
      case CalendarViewMode.month:
        format = CalendarFormat.month;
        break;
      case CalendarViewMode.week:
        format = CalendarFormat.week;
        break;
      case CalendarViewMode.day:
        format = CalendarFormat.week;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C173D24),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TableCalendar<CalendarEventModel>(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2035, 12, 31),
        focusedDay: selectedDate,
        calendarFormat: format,
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        eventLoader: (day) {
          return events.where((e) => isSameDay(e.eventDate, day)).toList();
        },
        onDaySelected: (selected, focused) {
          ref.read(calendarSelectedDateProvider.notifier).setDate(selected);
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          selectedDecoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x332E7D32),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          todayTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            fontSize: 14,
          ),
          selectedTextStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 14,
          ),
          defaultTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          weekendTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 4,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, dayEvents) {
            if (dayEvents.isEmpty) return const SizedBox.shrink();

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dayEvents.take(4).map((e) {
                final ev = e;
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: ev.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ev.color.withValues(alpha: 0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
