import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  farm,
  batch,
  vaccination,
  medicine,
  feed,
  water,
  inventory,
  finance,
  harvest,
  weather,
  ai,
  system,
  dg,
}

enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

enum NotificationStatus {
  unread,
  read,
  archived,
  pinned,
}

enum ReminderRepeat {
  once,
  daily,
  weekly,
  monthly,
  custom,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final String? relatedFarmId;
  final String? relatedBatchId;
  final String? actionUrl;
  final bool isSmartAlert;
  final bool isAiAlert;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.relatedFarmId,
    this.relatedBatchId,
    this.actionUrl,
    this.isSmartAlert = false,
    this.isAiAlert = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'relatedFarmId': relatedFarmId,
      'relatedBatchId': relatedBatchId,
      'actionUrl': actionUrl,
      'isSmartAlert': isSmartAlert,
      'isAiAlert': isAiAlert,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: json['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: parseDate(json['createdAt']),
      relatedFarmId: json['relatedFarmId'] as String?,
      relatedBatchId: json['relatedBatchId'] as String?,
      actionUrl: json['actionUrl'] as String?,
      isSmartAlert: json['isSmartAlert'] as bool? ?? false,
      isAiAlert: json['isAiAlert'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  NotificationModel copyWith({
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    String? relatedFarmId,
    String? relatedBatchId,
    String? actionUrl,
    bool? isSmartAlert,
    bool? isAiAlert,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      relatedFarmId: relatedFarmId ?? this.relatedFarmId,
      relatedBatchId: relatedBatchId ?? this.relatedBatchId,
      actionUrl: actionUrl ?? this.actionUrl,
      isSmartAlert: isSmartAlert ?? this.isSmartAlert,
      isAiAlert: isAiAlert ?? this.isAiAlert,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ReminderModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final ReminderRepeat repeat;
  final NotificationPriority priority;
  final String? farmId;
  final String? batchId;
  final String sound;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.repeat = ReminderRepeat.once,
    this.priority = NotificationPriority.normal,
    this.farmId,
    this.batchId,
    this.sound = 'default',
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
      'repeat': repeat.name,
      'priority': priority.name,
      'farmId': farmId,
      'batchId': batchId,
      'sound': sound,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return ReminderModel(
      id: json['id'] as String? ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Reminder',
      description: json['description'] as String? ?? '',
      date: parseDate(json['date']),
      time: json['time'] as String? ?? '08:00',
      repeat: ReminderRepeat.values.firstWhere(
        (e) => e.name == json['repeat'],
        orElse: () => ReminderRepeat.once,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      farmId: json['farmId'] as String?,
      batchId: json['batchId'] as String?,
      sound: json['sound'] as String? ?? 'default',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  ReminderModel copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? time,
    ReminderRepeat? repeat,
    NotificationPriority? priority,
    String? farmId,
    String? batchId,
    String? sound,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      repeat: repeat ?? this.repeat,
      priority: priority ?? this.priority,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      sound: sound ?? this.sound,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class NotificationSettingsModel {
  final bool pushEnabled;
  final bool localEnabled;
  final bool aiEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "06:00"
  final bool emergencyOverride;

  const NotificationSettingsModel({
    this.pushEnabled = true,
    this.localEnabled = true,
    this.aiEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '06:00',
    this.emergencyOverride = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'localEnabled': localEnabled,
      'aiEnabled': aiEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'emergencyOverride': emergencyOverride,
    };
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      localEnabled: json['localEnabled'] as bool? ?? true,
      aiEnabled: json['aiEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '06:00',
      emergencyOverride: json['emergencyOverride'] as bool? ?? true,
    );
  }

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? localEnabled,
    bool? aiEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? emergencyOverride,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      localEnabled: localEnabled ?? this.localEnabled,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      emergencyOverride: emergencyOverride ?? this.emergencyOverride,
    );
  }
}
