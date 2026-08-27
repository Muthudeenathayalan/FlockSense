import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/ai/data/models/ai_conversation_model.dart';
import 'package:flock_sense/features/ai/data/models/ai_message_model.dart';

class AiChatFirestoreService {
  AiChatFirestoreService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // In-memory offline cache fallback & immediate UI stream
  static final List<AiConversationModel> _localConversations = [];
  static final Map<String, List<AiMessageModel>> _localMessages = {};

  static final _messagesStreamController =
      StreamController<Map<String, List<AiMessageModel>>>.broadcast();

  static List<AiMessageModel> getLocalMessages(String conversationId) {
    return List.unmodifiable(_localMessages[conversationId] ?? []);
  }

  /// Stream list of user AI conversations with instant initial yield
  static Stream<List<AiConversationModel>> streamConversations() async* {
    yield List.unmodifiable(_localConversations);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final stream = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_conversations')
            .orderBy('updatedAt', descending: true)
            .snapshots();

        await for (final snap in stream) {
          final conversations = snap.docs
              .map((doc) => AiConversationModel.fromJson(doc.data()))
              .toList();
          _localConversations.clear();
          _localConversations.addAll(conversations);
          yield List.unmodifiable(_localConversations);
        }
      } catch (err) {
        debugPrint(
          '[AiChatFirestoreService] Error streaming conversations: $err',
        );
        yield List.unmodifiable(_localConversations);
      }
    }
  }

  /// Stream messages for a specific conversation with instant local yield & broadcast updates
  static Stream<List<AiMessageModel>> streamMessages(
    String conversationId,
  ) async* {
    if (conversationId.isEmpty) {
      yield const [];
      return;
    }

    // 1. Yield local in-memory messages immediately (0ms delay)
    yield List.unmodifiable(_localMessages[conversationId] ?? []);

    // 2. Background Firestore Listener
    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen(
            (snap) {
              final messages = snap.docs
                  .map((doc) => AiMessageModel.fromJson(doc.data()))
                  .toList();
              if (messages.isNotEmpty) {
                _localMessages[conversationId] = List.from(messages);
                _messagesStreamController.add(_localMessages);
              }
            },
            onError: (err) {
              debugPrint(
                '[AiChatFirestoreService] Error listening to messages: $err',
              );
            },
          );
    }

    // 3. Listen to local broadcast stream
    await for (final map in _messagesStreamController.stream) {
      if (map.containsKey(conversationId)) {
        yield List.unmodifiable(map[conversationId] ?? []);
      }
    }
  }

  static Future<AiConversationModel> createConversation({
    required String title,
    String? farmId,
    String? batchId,
  }) async {
    final user = _auth.currentUser;
    final convId = 'conv_${DateTime.now().millisecondsSinceEpoch}';

    final conversation = AiConversationModel(
      id: convId,
      title: title,
      farmId: farmId,
      batchId: batchId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _localConversations.insert(0, conversation);
    _localMessages[convId] = [];
    _messagesStreamController.add(_localMessages);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_conversations')
            .doc(convId)
            .set(conversation.toJson());
      } catch (e) {
        debugPrint('[AiChatFirestoreService] Firestore create failed: $e');
      }
    }

    return conversation;
  }

  static Future<void> saveMessage(AiMessageModel message) async {
    final user = _auth.currentUser;
    final convId = message.conversationId;

    final list = List<AiMessageModel>.from(_localMessages[convId] ?? []);
    list.removeWhere((m) => m.id == message.id);
    list.add(message);
    _localMessages[convId] = list;

    // Immediately broadcast to local UI stream!
    _messagesStreamController.add(_localMessages);

    // Update last preview
    final convIndex = _localConversations.indexWhere((c) => c.id == convId);
    if (convIndex != -1) {
      _localConversations[convIndex] = _localConversations[convIndex].copyWith(
        lastMessagePreview: message.content,
        updatedAt: DateTime.now(),
      );
    }

    if (user != null && convId.isNotEmpty) {
      try {
        final convRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_conversations')
            .doc(convId);

        await convRef
            .collection('messages')
            .doc(message.id)
            .set(message.toJson());

        await convRef.update({
          'lastMessagePreview': message.content,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint(
          '[AiChatFirestoreService] Firestore save message failed: $e',
        );
      }
    }
  }

  static Future<void> togglePinConversation(
    String conversationId,
    bool isPinned,
  ) async {
    final user = _auth.currentUser;
    final index = _localConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _localConversations[index] = _localConversations[index].copyWith(
        isPinned: isPinned,
      );
    }

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_conversations')
            .doc(conversationId)
            .update({'isPinned': isPinned});
      } catch (e) {
        debugPrint('[AiChatFirestoreService] Toggle pin failed: $e');
      }
    }
  }

  static Future<void> renameConversation(
    String conversationId,
    String newTitle,
  ) async {
    final user = _auth.currentUser;
    final index = _localConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _localConversations[index] = _localConversations[index].copyWith(
        title: newTitle,
      );
    }

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_conversations')
            .doc(conversationId)
            .update({'title': newTitle});
      } catch (e) {
        debugPrint('[AiChatFirestoreService] Rename failed: $e');
      }
    }
  }

  static Future<void> deleteConversation(String conversationId) async {
    final user = _auth.currentUser;
    _localConversations.removeWhere((c) => c.id == conversationId);
    _localMessages.remove(conversationId);
    _messagesStreamController.add(_localMessages);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_conversations')
            .doc(conversationId)
            .delete();
      } catch (e) {
        debugPrint('[AiChatFirestoreService] Delete conversation failed: $e');
      }
    }
  }
}
