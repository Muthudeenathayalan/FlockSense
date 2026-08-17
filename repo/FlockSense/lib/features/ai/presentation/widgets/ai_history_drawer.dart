import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/ai/data/models/ai_conversation_model.dart';
import 'package:flock_sense/features/ai/data/services/ai_chat_firestore_service.dart';
import 'package:flock_sense/features/ai/domain/ai_providers.dart';

class AiHistoryDrawer extends ConsumerStatefulWidget {
  const AiHistoryDrawer({super.key});

  @override
  ConsumerState<AiHistoryDrawer> createState() => _AiHistoryDrawerState();
}

class _AiHistoryDrawerState extends ConsumerState<AiHistoryDrawer> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsStreamProvider);
    final activeConv = ref.watch(activeConversationProvider);
    final searchQuery = _searchController.text.trim().toLowerCase();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0A3200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI Chat History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: 'New Chat',
                        onPressed: () {
                          ref.read(activeConversationProvider.notifier).setConversation(null);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withAlpha((0.15 * 255).toInt()),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),

            // Conversation List Stream
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  final filtered = conversations.where((c) {
                    if (searchQuery.isEmpty) return true;
                    return c.title.toLowerCase().contains(searchQuery) ||
                        (c.lastMessagePreview?.toLowerCase().contains(searchQuery) ?? false);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No matching conversations.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = activeConv?.id == item.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.green.shade50,
                        leading: Icon(
                          item.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                          size: 18,
                          color: item.isPinned ? Colors.orange.shade800 : const Color(0xFF1B5E20),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          item.lastMessagePreview ?? DateFormat('dd MMM, HH:mm').format(item.updatedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                          onSelected: (val) async {
                            if (val == 'pin') {
                              await AiChatFirestoreService.togglePinConversation(item.id, !item.isPinned);
                            } else if (val == 'rename') {
                              _showRenameDialog(context, item);
                            } else if (val == 'delete') {
                              await AiChatFirestoreService.deleteConversation(item.id);
                              if (activeConv?.id == item.id) {
                                ref.read(activeConversationProvider.notifier).setConversation(null);
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'pin', child: Text(item.isPinned ? 'Unpin' : 'Pin')),
                            const PopupMenuItem(value: 'rename', child: Text('Rename')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                        onTap: () {
                          ref.read(activeConversationProvider.notifier).setConversation(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AiConversationModel item) {
    final controller = TextEditingController(text: item.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await AiChatFirestoreService.renameConversation(item.id, controller.text.trim());
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
