import 'package:flock_sense/features/ai/data/models/ai_attachment_model.dart';

enum AiMessageSender { user, ai, system }

enum AiMessageType { text, image, file, analysis, chart, recommendation }

class AiMessageModel {
  final String id;
  final String conversationId;
  final AiMessageSender sender;
  final String content;
  final DateTime timestamp;
  final AiMessageType messageType;
  final List<AiAttachmentModel> attachments;
  final Map<String, dynamic>? chartData;
  final bool isStreaming;
  final bool hasError;
  final String? errorMessage;
  final String? userFeedback; // 'liked', 'disliked'

  const AiMessageModel({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.messageType = AiMessageType.text,
    this.attachments = const [],
    this.chartData,
    this.isStreaming = false,
    this.hasError = false,
    this.errorMessage,
    this.userFeedback,
  });

  AiMessageModel copyWith({
    String? id,
    String? conversationId,
    AiMessageSender? sender,
    String? content,
    DateTime? timestamp,
    AiMessageType? messageType,
    List<AiAttachmentModel>? attachments,
    Map<String, dynamic>? chartData,
    bool? isStreaming,
    bool? hasError,
    String? errorMessage,
    String? userFeedback,
  }) {
    return AiMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      attachments: attachments ?? this.attachments,
      chartData: chartData ?? this.chartData,
      isStreaming: isStreaming ?? this.isStreaming,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.name,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'chartData': chartData,
      'userFeedback': userFeedback,
    };
  }

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      sender: AiMessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => AiMessageSender.ai,
      ),
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      messageType: AiMessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => AiMessageType.text,
      ),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (a) => AiAttachmentModel.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      chartData: json['chartData'] as Map<String, dynamic>?,
      userFeedback: json['userFeedback'] as String?,
    );
  }
}
