import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
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
      // 1. Ensure Active Conversation with currently selected Firebase Farm
      final activeFarmId = ref.read(selectedDashboardFarmIdProvider) ??
          ref.read(activeFarmIdProvider).value;
      final activeNotifier = ref.read(activeConversationProvider.notifier);
      final conversation = await activeNotifier.ensureActiveConversation(
        farmId: activeFarmId,
      );

      // Retrieve existing conversation history BEFORE adding the new message
      final existingHistory =
          AiChatFirestoreService.getLocalMessages(conversation.id);

      // Auto-title the conversation in Firestore if this is the first message
      if (existingHistory.isEmpty && userText.trim().isNotEmpty) {
        final shortTitle = userText.trim().length > 32
            ? '${userText.trim().substring(0, 32)}...'
            : userText.trim();
        unawaited(
          AiChatFirestoreService.renameConversation(conversation.id, shortTitle),
        );
      }

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

      // 4. Build Live Farm Snapshot Context from Firebase Firestore
      final contextSnapshot = await AiContextBuilder.buildFarmContext(
        farmId: conversation.farmId ?? activeFarmId,
        batchId: conversation.batchId,
      );

      // 5. Extract local image bytes if attached
      final imageBytesList = <Uint8List>[];
      final imageMimeTypes = <String>[];
      for (final att in attachments) {
        if (att.localPath != null && att.fileType == AiAttachmentType.image) {
          try {
            final file = File(att.localPath!);
            if (await file.exists()) {
              imageBytesList.add(await file.readAsBytes());
              imageMimeTypes.add(att.mimeType ?? 'image/jpeg');
            }
          } catch (e) {
            debugPrint('[AiScreen] Error reading attachment: $e');
          }
        }
      }

      // 6. Call Gemini Service with Multi-Turn History & Images
      final aiResponseText = await GeminiService.generateResponse(
        prompt: userText.isNotEmpty
            ? userText
            : 'Analyze the uploaded image and flock telemetry.',
        contextSnapshot: contextSnapshot,
        conversationHistory: existingHistory,
        imageBytesList: imageBytesList.isNotEmpty ? imageBytesList : null,
        imageMimeTypes: imageMimeTypes.isNotEmpty ? imageMimeTypes : null,
      );

      // 7. Update AI Message
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
          OutlinedButton(
            onPressed: () async {
              final testKey = controller.text.trim();
              final ok = await GeminiService.testApiKey(testKey.isNotEmpty ? testKey : null);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? Colors.green.shade800 : Colors.red.shade800,
                    content: Text(
                      ok
                          ? 'Connection Successful! Gemini 3.6 Flash is live.'
                          : 'Connection failed. Please verify your API key.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Test Connection'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF104422),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await GeminiService.setStoredApiKey(controller.text.trim());
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
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
      backgroundColor: AppColors.background,
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF104422).withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.psychology,
                            size: 44,
                            color: Color(0xFF104422),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'FlockSense AI Advisor',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF104422),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your 24/7 intelligent poultry consultant. Powered by Gemini 3.6 Flash with real-time flock telemetry.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStarterCard(
                          icon: Icons.analytics_outlined,
                          title: 'Flock Performance Review',
                          subtitle: 'Analyze current FCR, weight & standard growth',
                          prompt:
                              'Analyze my current active flock performance and FCR against breed standards.',
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                        ),
                        const SizedBox(height: 10),
                        _buildStarterCard(
                          icon: Icons.warning_amber_rounded,
                          title: 'Mortality & Health Diagnostic',
                          subtitle: 'Root-cause analysis and biosecurity action steps',
                          prompt:
                              'Review mortality trends in my farm and recommend corrective action steps.',
                          color: const Color(0xFFDC2626),
                          bgColor: const Color(0xFFFEF2F2),
                        ),
                        const SizedBox(height: 10),
                        _buildStarterCard(
                          icon: Icons.grain_outlined,
                          title: 'Feed Management & Transition',
                          subtitle: 'Optimal daily feed intake and phase schedule',
                          prompt:
                              'What are the recommended feed intake targets and phase transitions for my flock age?',
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFFFBEB),
                        ),
                        const SizedBox(height: 10),
                        _buildStarterCard(
                          icon: Icons.camera_alt_outlined,
                          title: 'Photo Symptom Diagnostic',
                          subtitle: 'Upload bird or feces photos for visual inspection',
                          prompt:
                              'How do I identify early signs of respiratory stress or digestive disorders in my birds?',
                          color: const Color(0xFF16A34A),
                          bgColor: const Color(0xFFF0FDF4),
                        ),
                      ],
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

  Widget _buildStarterCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String prompt,
    required Color color,
    required Color bgColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSendMessage(prompt, []),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: color.withAlpha(160),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
