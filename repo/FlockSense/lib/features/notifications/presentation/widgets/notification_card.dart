import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(notification.priority);
    final icon = _getTypeIcon(notification.type);
    final isUnread = notification.status == NotificationStatus.unread;
    final isPinned = notification.status == NotificationStatus.pinned;

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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
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
