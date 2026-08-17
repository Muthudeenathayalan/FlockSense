import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/ai/data/models/ai_attachment_model.dart';
import 'package:flock_sense/features/ai/data/models/ai_conversation_model.dart';
import 'package:flock_sense/features/ai/data/models/ai_message_model.dart';
import 'package:flock_sense/features/ai/data/services/ai_chat_firestore_service.dart';

class ActiveConversationNotifier extends Notifier<AiConversationModel?> {
  @override
  AiConversationModel? build() => null;

  void setConversation(AiConversationModel? conversation) {
    state = conversation;
  }

  Future<AiConversationModel> ensureActiveConversation({
    String? farmId,
    String? batchId,
  }) async {
    if (state != null) return state!;

    final newConv = await AiChatFirestoreService.createConversation(
      title: 'New AI Chat',
      farmId: farmId,
      batchId: batchId,
    );
    state = newConv;
    return newConv;
  }
}

final activeConversationProvider =
    NotifierProvider<ActiveConversationNotifier, AiConversationModel?>(
  ActiveConversationNotifier.new,
);

class AiSendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSending(bool value) {
    state = value;
  }
}

final aiSendingStateProvider =
    NotifierProvider<AiSendingNotifier, bool>(AiSendingNotifier.new);

class ActiveAttachmentsNotifier extends Notifier<List<AiAttachmentModel>> {
  @override
  List<AiAttachmentModel> build() => const [];

  void setAttachments(List<AiAttachmentModel> list) {
    state = list;
  }

  void add(AiAttachmentModel attachment) {
    state = [...state, attachment];
  }

  void remove(AiAttachmentModel attachment) {
    state = state.where((a) => a.id != attachment.id).toList();
  }

  void clear() {
    state = const [];
  }
}

final activeAttachmentsProvider =
    NotifierProvider<ActiveAttachmentsNotifier, List<AiAttachmentModel>>(
  ActiveAttachmentsNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final conversationsStreamProvider = StreamProvider<List<AiConversationModel>>((ref) {
  return AiChatFirestoreService.streamConversations();
});

final messagesStreamProvider = StreamProvider.family<List<AiMessageModel>, String>((ref, conversationId) {
  return AiChatFirestoreService.streamMessages(conversationId);
});
