import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/calendar/presentation/providers/calendar_providers.dart';

class TodaysSummaryCard extends StatelessWidget {
  const TodaysSummaryCard({super.key, required this.stats});

  final CalendarStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _card(
            title: "Today's Events",
            value: '${stats.todaysEvents}',
            subtitle: 'Scheduled today',
            icon: Icons.today_rounded,
            startColor: const Color(0xFF2E7D32),
            endColor: const Color(0xFF1B5E20),
          ),
          const SizedBox(width: 10),
          _card(
            title: 'Pending Action',
            value: '${stats.pendingEvents}',
            subtitle: 'Tasks to complete',
            icon: Icons.pending_actions_rounded,
            startColor: const Color(0xFF0284C7),
            endColor: const Color(0xFF0369A1),
          ),
          const SizedBox(width: 10),
          _card(
            title: 'Overdue Alert',
            value: '${stats.overdueEvents}',
            subtitle: stats.overdueEvents > 0 ? 'Requires immediate action' : 'No overdue events',
            icon: Icons.warning_amber_rounded,
            startColor: stats.overdueEvents > 0 ? const Color(0xFFE53935) : const Color(0xFF10B981),
            endColor: stats.overdueEvents > 0 ? const Color(0xFFC62828) : const Color(0xFF059669),
          ),
          const SizedBox(width: 10),
          _card(
            title: 'Upcoming Week',
            value: '${stats.upcomingThisWeek}',
            subtitle: 'Next 7 days',
            icon: Icons.calendar_month_rounded,
            startColor: const Color(0xFF8E24AA),
            endColor: const Color(0xFF6A1B9A),
          ),
          const SizedBox(width: 10),
          _card(
            title: 'Completed',
            value: '${stats.completedEvents}',
            subtitle: 'History logged',
            icon: Icons.task_alt_rounded,
            startColor: const Color(0xFF43A047),
            endColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color startColor,
    required Color endColor,
  }) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [startColor, endColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: startColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: startColor == const Color(0xFFE53935) ? const Color(0xFFE53935) : AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: startColor == const Color(0xFFE53935) && stats.overdueEvents > 0
                  ? const Color(0xFFE53935)
                  : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
