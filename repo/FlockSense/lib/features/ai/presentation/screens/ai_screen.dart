import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/ai/data/models/ai_attachment_model.dart';
import 'package:flock_sense/features/ai/data/models/ai_message_model.dart';
import 'package:flock_sense/features/ai/data/services/ai_chat_firestore_service.dart';
import 'package:flock_sense/features/ai/data/services/ai_context_builder.dart';
import 'package:flock_sense/features/ai/data/services/gemini_service.dart';
import 'package:flock_sense/features/ai/domain/ai_providers.dart';
import 'package:flock_sense/features/ai/presentation/widgets/ai_app_bar.dart';
import 'package:flock_sense/features/ai/presentation/widgets/ai_chat_bubble.dart';
import 'package:flock_sense/features/ai/presentation/widgets/ai_history_drawer.dart';
import 'package:flock_sense/features/ai/presentation/widgets/ai_input_bar.dart';
import 'package:flock_sense/features/ai/presentation/widgets/ai_prompt_chips.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(
    String userText,
    List<AiAttachmentModel> attachments,
  ) async {
    final isSending = ref.read(aiSendingStateProvider);
    if (isSending) return;

    ref.read(aiSendingStateProvider.notifier).setSending(true);

    try {
      // 1. Ensure Active Conversation
      final activeNotifier = ref.read(activeConversationProvider.notifier);
      final conversation = await activeNotifier.ensureActiveConversation();

      // 2. Save User Message
      final userMessage = AiMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversation.id,
        sender: AiMessageSender.user,
        content: userText,
        timestamp: DateTime.now(),
        attachments: attachments,
      );

      await AiChatFirestoreService.saveMessage(userMessage);
      ref.invalidate(messagesStreamProvider(conversation.id));
      _scrollToBottom();

      // 3. Save Initial Streaming AI Placeholder
      final aiMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch + 1}';
      final initialAiMessage = AiMessageModel(
        id: aiMsgId,
        conversationId: conversation.id,
        sender: AiMessageSender.ai,
        content: 'Analyzing flock telemetry and generating response...',
        timestamp: DateTime.now(),
        isStreaming: true,
      );

      await AiChatFirestoreService.saveMessage(initialAiMessage);
      ref.invalidate(messagesStreamProvider(conversation.id));
      _scrollToBottom();

      // 4. Build Live Farm Snapshot Context
      final contextSnapshot = await AiContextBuilder.buildFarmContext(
        farmId: conversation.farmId,
        batchId: conversation.batchId,
      );

      // 5. Call Gemini Service
      final aiResponseText = await GeminiService.generateResponse(
        prompt: userText.isNotEmpty
            ? userText
            : 'Analyze the uploaded content and telemetry.',
        contextSnapshot: contextSnapshot,
      );

      // 6. Update AI Message
      final completedAiMessage = initialAiMessage.copyWith(
        content: aiResponseText,
        isStreaming: false,
      );

      await AiChatFirestoreService.saveMessage(completedAiMessage);
      ref.invalidate(messagesStreamProvider(conversation.id));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating AI response: $e')),
        );
      }
    } finally {
      ref.read(aiSendingStateProvider.notifier).setSending(false);
    }
  }

  void _openSettingsDialog() async {
    final currentKey = await GeminiService.getStoredApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FlockSense AI Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Gemini API Key below. (Keys are stored securely in encrypted device storage and never exposed).',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await GeminiService.setStoredApiKey(controller.text.trim());
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gemini API key saved successfully.'),
                  ),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeConv = ref.watch(activeConversationProvider);
    final isSending = ref.watch(aiSendingStateProvider);

    final messagesAsync = activeConv != null
        ? ref.watch(messagesStreamProvider(activeConv.id))
        : const AsyncValue<List<AiMessageModel>>.data([]);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AiAppBar(
        onOpenHistory: () => _scaffoldKey.currentState?.openEndDrawer(),
        onNewChat: () {
          ref.read(activeConversationProvider.notifier).setConversation(null);
        },
        onOpenSettings: _openSettingsDialog,
      ),
      endDrawer: const AiHistoryDrawer(),
      body: Column(
        children: [
          // Prompt Suggestions Bar
          AiPromptChips(
            onSelectPrompt: (prompt) => _handleSendMessage(prompt, []),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Messages List View
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1B5E20,
                              ).withAlpha((0.1 * 255).toInt()),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.psychology,
                              size: 48,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome to FlockSense AI Workspace',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ask any question about your flock, analyze photos, upload reports, or generate performance predictions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return AiChatBubble(
                      message: msg,
                      onRegenerate: () {
                        if (msg.sender == AiMessageSender.ai) {
                          _handleSendMessage(
                            'Regenerate response for previous query',
                            [],
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error loading messages: $e')),
            ),
          ),

          // Bottom Input Bar
          AiInputBar(
            onSend: _handleSendMessage,
            isSending: isSending,
            onStop: () =>
                ref.read(aiSendingStateProvider.notifier).setSending(false),
          ),
        ],
      ),
    );
  }
}
