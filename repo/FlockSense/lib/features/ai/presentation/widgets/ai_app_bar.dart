import 'package:flutter/material.dart';

class AiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenHistory;
  final VoidCallback onNewChat;
  final VoidCallback onOpenSettings;

  const AiAppBar({
    super.key,
    required this.onOpenHistory,
    required this.onNewChat,
    required this.onOpenSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.history_outlined, color: Color(0xFF1B5E20)),
        tooltip: 'Chat History',
        onPressed: onOpenHistory,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Text(
                'FlockSense AI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('ONLINE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Live Farm Telemetry Context Active',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: Color(0xFF1B5E20)),
          tooltip: 'New Conversation',
          onPressed: onNewChat,
        ),
        IconButton(
          icon: const Icon(Icons.tune_outlined, color: Colors.black54),
          tooltip: 'AI Settings',
          onPressed: onOpenSettings,
        ),
      ],
    );
  }
}
