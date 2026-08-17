import 'package:flutter/material.dart';

class NotificationKpiHeader extends StatelessWidget {
  final int unreadCount;
  final int todayAlertsCount;
  final int criticalAlertsCount;
  final int completedRemindersCount;

  const NotificationKpiHeader({
    super.key,
    required this.unreadCount,
    required this.todayAlertsCount,
    required this.criticalAlertsCount,
    required this.completedRemindersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildItem('Unread', '$unreadCount', Icons.mark_email_unread_outlined, const Color(0xFF1B5E20)),
          _buildDivider(),
          _buildItem("Today's", '$todayAlertsCount', Icons.today_outlined, const Color(0xFF00838F)),
          _buildDivider(),
          _buildItem('Critical', '$criticalAlertsCount', Icons.warning_amber_rounded, const Color(0xFFE65100)),
          _buildDivider(),
          _buildItem('Reminders', '$completedRemindersCount', Icons.task_alt_outlined, Colors.purple.shade700),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade300,
    );
  }
}
