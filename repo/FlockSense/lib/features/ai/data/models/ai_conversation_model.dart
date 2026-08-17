class AiConversationModel {
  final String id;
  final String title;
  final String? farmId;
  final String? batchId;
  final bool isPinned;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessagePreview;

  const AiConversationModel({
    required this.id,
    required this.title,
    this.farmId,
    this.batchId,
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessagePreview,
  });

  AiConversationModel copyWith({
    String? id,
    String? title,
    String? farmId,
    String? batchId,
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessagePreview,
  }) {
    return AiConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'farmId': farmId,
      'batchId': batchId,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
    };
  }

  factory AiConversationModel.fromJson(Map<String, dynamic> json) {
    return AiConversationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'New Conversation',
      farmId: json['farmId'] as String?,
      batchId: json['batchId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }
}
