import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({super.key, required this.notification});

  Color _getPriorityColor(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.critical:
        return Colors.red;
      case NotificationPriority.high:
        return const Color(0xFFE65100);
      case NotificationPriority.normal:
        return const Color(0xFF1B5E20);
      case NotificationPriority.low:
        return Colors.grey.shade600;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.farm:
        return Icons.agriculture;
      case NotificationType.batch:
        return Icons.group_work_outlined;
      case NotificationType.vaccination:
        return Icons.vaccines_outlined;
      case NotificationType.medicine:
        return Icons.medication_outlined;
      case NotificationType.feed:
        return Icons.grass;
      case NotificationType.water:
        return Icons.water_drop_outlined;
      case NotificationType.inventory:
        return Icons.inventory_2_outlined;
      case NotificationType.finance:
        return Icons.attach_money;
      case NotificationType.harvest:
        return Icons.shopping_basket_outlined;
      case NotificationType.weather:
        return Icons.cloud_outlined;
      case NotificationType.ai:
        return Icons.psychology;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.dg:
        return Icons.electric_bolt_outlined;
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(notification.priority);
    final icon = _getTypeIcon(notification.type);
    final isUnread = notification.status == NotificationStatus.unread;
    final isPinned = notification.status == NotificationStatus.pinned;

    final metadata = notification.metadata ?? {};
    final rawRecs = metadata['recommendations'];
    final recommendations = rawRecs is List
        ? rawRecs.map((e) => e.toString()).toList()
        : <String>[];
    final hasRecommendations = recommendations.isNotEmpty;
    final phase = metadata['phase']?.toString();
    final targetWeight = metadata['targetWeightGrams'];
    final feedTarget = metadata['totalEstimatedFeedKg'];
    final isDailyRecordPrompt = notification.id.startsWith('daily_record_pending') ||
        notification.actionUrl == '/daily-record';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isUnread
            ? Colors.green.shade50.withAlpha((0.5 * 255).toInt())
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPinned
              ? const Color(0xFF1B5E20)
              : (notification.priority == NotificationPriority.critical
                    ? Colors.red.shade300
                    : Colors.grey.shade200),
          width: isPinned ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () async {
          if (isUnread) {
            await NotificationFirestoreService.markAsRead(notification.id);
          }
          if (isDailyRecordPrompt) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DailyRecordsDashboardScreen(),
              ),
            );
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: priorityColor.withAlpha((0.15 * 255).toInt()),
          child: Icon(icon, color: priorityColor, size: 20),
        ),
        title: Row(
          children: [
            if (isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.push_pin, size: 14, color: Color(0xFF1B5E20)),
              ),
            Expanded(
              child: Text(
                notification.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                notification.priority.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: isDailyRecordPrompt ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
            if (phase != null || targetWeight != null || feedTarget != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (phase != null)
                    _buildBadge('Phase: $phase', const Color(0xFF1B5E20)),
                  if (targetWeight != null)
                    _buildBadge('Target: ${targetWeight}g', Colors.blue.shade800),
                  if (feedTarget != null)
                    _buildBadge('Daily Feed: ${feedTarget}kg', Colors.orange.shade900),
                ],
              ),
            ],
            if (hasRecommendations) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1B5E20).withAlpha(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: Color(0xFF1B5E20),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Today's Recommendations",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...recommendations.take(3).map(
                          (rec) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "• ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
            if (isDailyRecordPrompt) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.edit_calendar, size: 14),
                  label: const Text(
                    'Enter Daily Data',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DailyRecordsDashboardScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(notification.createdAt),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
          onSelected: (val) async {
            switch (val) {
              case 'read':
                await NotificationFirestoreService.markAsRead(notification.id);
                break;
              case 'pin':
                await NotificationFirestoreService.togglePin(notification.id);
                break;
              case 'archive':
                await NotificationFirestoreService.archiveNotification(
                  notification.id,
                );
                break;
              case 'delete':
                await NotificationFirestoreService.deleteNotification(
                  notification.id,
                );
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'read',
              child: Text(isUnread ? 'Mark as Read' : 'Mark as Unread'),
            ),
            PopupMenuItem(
              value: 'pin',
              child: Text(isPinned ? 'Unpin Alert' : 'Pin to Top'),
            ),
            const PopupMenuItem(value: 'archive', child: Text('Archive Alert')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete Alert', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
