import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferencesModel {
  // Account
  final String displayName;
  final String phone;
  final String role;
  final DateTime accountCreatedDate;
  final DateTime lastLoginDate;

  // App Appearance
  final String themeMode; // 'system', 'light', 'dark'
  final int accentColorValue;
  final String fontSize; // 'Small', 'Medium', 'Large'
  final String animationSpeed; // 'Normal', 'Fast', 'Disabled'
  final String cardStyle; // 'Rounded', 'Flat', 'Elevated'
  final bool enableDynamicColors;

  // Language
  final String languageCode; // 'en', 'ta'

  // Units
  final String weightUnit; // 'kg', 'g'
  final String distanceUnit; // 'Meter', 'Feet'
  final String temperatureUnit; // '°C', '°F'
  final String currency; // 'INR (₹)', 'USD ($)', 'EUR (€)'

  // Notifications
  final bool pushEnabled;
  final bool aiNotifsEnabled;
  final bool dailySummaryEnabled;
  final bool vaccineAlertsEnabled;
  final bool inventoryAlertsEnabled;
  final bool financeAlertsEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String notificationSound;
  final bool vibration;

  // AI Settings
  final String aiModel; // 'Gemini 1.5 Flash', 'Gemini 1.5 Pro'
  final String responseStyle; // 'Brief', 'Balanced', 'Detailed'
  final bool aiMemoryEnabled;
  final bool useFarmContext;
  final bool useBatchContext;
  final bool imageAnalysis;
  final bool fileAnalysis;
  final bool streamingResponses;

  // Data & Storage
  final double cacheSizeMb;
  final double storageUsedMb;

  // Backup & Sync
  final bool autoBackupEnabled;
  final DateTime? lastBackupTime;
  final String cloudSyncStatus; // 'Synced', 'Syncing', 'Pending'

  // Privacy & Security
  final bool biometricLogin;
  final bool pinLock;
  final int autoLogoutMinutes;

  // Advanced
  final bool developerMode;
  final bool exportLogsEnabled;

  UserPreferencesModel({
    this.displayName = 'Farm Owner',
    this.phone = '+91 98765 43210',
    this.role = 'Farm Owner / Lead Manager',
    DateTime? accountCreatedDate,
    DateTime? lastLoginDate,
    this.themeMode = 'system',
    this.accentColorValue = 0xFF1B5E20,
    this.fontSize = 'Medium',
    this.animationSpeed = 'Normal',
    this.cardStyle = 'Rounded',
    this.enableDynamicColors = true,
    this.languageCode = 'en',
    this.weightUnit = 'kg',
    this.distanceUnit = 'Meter',
    this.temperatureUnit = '°C',
    this.currency = 'INR (₹)',
    this.pushEnabled = true,
    this.aiNotifsEnabled = true,
    this.dailySummaryEnabled = true,
    this.vaccineAlertsEnabled = true,
    this.inventoryAlertsEnabled = true,
    this.financeAlertsEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '06:00',
    this.notificationSound = 'Default',
    this.vibration = true,
    this.aiModel = 'Gemini 1.5 Flash',
    this.responseStyle = 'Balanced',
    this.aiMemoryEnabled = true,
    this.useFarmContext = true,
    this.useBatchContext = true,
    this.imageAnalysis = true,
    this.fileAnalysis = true,
    this.streamingResponses = true,
    this.cacheSizeMb = 42.5,
    this.storageUsedMb = 128.4,
    this.autoBackupEnabled = true,
    this.lastBackupTime,
    this.cloudSyncStatus = 'Synced',
    this.biometricLogin = false,
    this.pinLock = false,
    this.autoLogoutMinutes = 30,
    this.developerMode = false,
    this.exportLogsEnabled = false,
  }) : accountCreatedDate = accountCreatedDate ?? DateTime(2025, 1, 15),
       lastLoginDate = lastLoginDate ?? DateTime(2026, 8, 16);

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'phone': phone,
      'role': role,
      'accountCreatedDate': Timestamp.fromDate(accountCreatedDate),
      'lastLoginDate': Timestamp.fromDate(lastLoginDate),
      'themeMode': themeMode,
      'accentColorValue': accentColorValue,
      'fontSize': fontSize,
      'animationSpeed': animationSpeed,
      'cardStyle': cardStyle,
      'enableDynamicColors': enableDynamicColors,
      'languageCode': languageCode,
      'weightUnit': weightUnit,
      'distanceUnit': distanceUnit,
      'temperatureUnit': temperatureUnit,
      'currency': currency,
      'pushEnabled': pushEnabled,
      'aiNotifsEnabled': aiNotifsEnabled,
      'dailySummaryEnabled': dailySummaryEnabled,
      'vaccineAlertsEnabled': vaccineAlertsEnabled,
      'inventoryAlertsEnabled': inventoryAlertsEnabled,
      'financeAlertsEnabled': financeAlertsEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'notificationSound': notificationSound,
      'vibration': vibration,
      'aiModel': aiModel,
      'responseStyle': responseStyle,
      'aiMemoryEnabled': aiMemoryEnabled,
      'useFarmContext': useFarmContext,
      'useBatchContext': useBatchContext,
      'imageAnalysis': imageAnalysis,
      'fileAnalysis': fileAnalysis,
      'streamingResponses': streamingResponses,
      'cacheSizeMb': cacheSizeMb,
      'storageUsedMb': storageUsedMb,
      'autoBackupEnabled': autoBackupEnabled,
      'lastBackupTime': lastBackupTime != null
          ? Timestamp.fromDate(lastBackupTime!)
          : null,
      'cloudSyncStatus': cloudSyncStatus,
      'biometricLogin': biometricLogin,
      'pinLock': pinLock,
      'autoLogoutMinutes': autoLogoutMinutes,
      'developerMode': developerMode,
      'exportLogsEnabled': exportLogsEnabled,
    };
  }

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return UserPreferencesModel(
      displayName: json['displayName'] as String? ?? 'Farm Owner',
      phone: json['phone'] as String? ?? '+91 98765 43210',
      role: json['role'] as String? ?? 'Farm Owner / Lead Manager',
      accountCreatedDate: parseDate(json['accountCreatedDate']),
      lastLoginDate: parseDate(json['lastLoginDate']),
      themeMode: json['themeMode'] as String? ?? 'system',
      accentColorValue: json['accentColorValue'] as int? ?? 0xFF1B5E20,
      fontSize: json['fontSize'] as String? ?? 'Medium',
      animationSpeed: json['animationSpeed'] as String? ?? 'Normal',
      cardStyle: json['cardStyle'] as String? ?? 'Rounded',
      enableDynamicColors: json['enableDynamicColors'] as bool? ?? true,
      languageCode: json['languageCode'] as String? ?? 'en',
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      distanceUnit: json['distanceUnit'] as String? ?? 'Meter',
      temperatureUnit: json['temperatureUnit'] as String? ?? '°C',
      currency: json['currency'] as String? ?? 'INR (₹)',
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      aiNotifsEnabled: json['aiNotifsEnabled'] as bool? ?? true,
      dailySummaryEnabled: json['dailySummaryEnabled'] as bool? ?? true,
      vaccineAlertsEnabled: json['vaccineAlertsEnabled'] as bool? ?? true,
      inventoryAlertsEnabled: json['inventoryAlertsEnabled'] as bool? ?? true,
      financeAlertsEnabled: json['financeAlertsEnabled'] as bool? ?? true,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '06:00',
      notificationSound: json['notificationSound'] as String? ?? 'Default',
      vibration: json['vibration'] as bool? ?? true,
      aiModel: json['aiModel'] as String? ?? 'Gemini 1.5 Flash',
      responseStyle: json['responseStyle'] as String? ?? 'Balanced',
      aiMemoryEnabled: json['aiMemoryEnabled'] as bool? ?? true,
      useFarmContext: json['useFarmContext'] as bool? ?? true,
      useBatchContext: json['useBatchContext'] as bool? ?? true,
      imageAnalysis: json['imageAnalysis'] as bool? ?? true,
      fileAnalysis: json['fileAnalysis'] as bool? ?? true,
      streamingResponses: json['streamingResponses'] as bool? ?? true,
      cacheSizeMb: (json['cacheSizeMb'] as num?)?.toDouble() ?? 42.5,
      storageUsedMb: (json['storageUsedMb'] as num?)?.toDouble() ?? 128.4,
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? true,
      lastBackupTime: json['lastBackupTime'] != null
          ? parseDate(json['lastBackupTime'])
          : null,
      cloudSyncStatus: json['cloudSyncStatus'] as String? ?? 'Synced',
      biometricLogin: json['biometricLogin'] as bool? ?? false,
      pinLock: json['pinLock'] as bool? ?? false,
      autoLogoutMinutes: json['autoLogoutMinutes'] as int? ?? 30,
      developerMode: json['developerMode'] as bool? ?? false,
      exportLogsEnabled: json['exportLogsEnabled'] as bool? ?? false,
    );
  }

  UserPreferencesModel copyWith({
    String? displayName,
    String? phone,
    String? role,
    DateTime? accountCreatedDate,
    DateTime? lastLoginDate,
    String? themeMode,
    int? accentColorValue,
    String? fontSize,
    String? animationSpeed,
    String? cardStyle,
    bool? enableDynamicColors,
    String? languageCode,
    String? weightUnit,
    String? distanceUnit,
    String? temperatureUnit,
    String? currency,
    bool? pushEnabled,
    bool? aiNotifsEnabled,
    bool? dailySummaryEnabled,
    bool? vaccineAlertsEnabled,
    bool? inventoryAlertsEnabled,
    bool? financeAlertsEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? notificationSound,
    bool? vibration,
    String? aiModel,
    String? responseStyle,
    bool? aiMemoryEnabled,
    bool? useFarmContext,
    bool? useBatchContext,
    bool? imageAnalysis,
    bool? fileAnalysis,
    bool? streamingResponses,
    double? cacheSizeMb,
    double? storageUsedMb,
    bool? autoBackupEnabled,
    DateTime? lastBackupTime,
    String? cloudSyncStatus,
    bool? biometricLogin,
    bool? pinLock,
    int? autoLogoutMinutes,
    bool? developerMode,
    bool? exportLogsEnabled,
  }) {
    return UserPreferencesModel(
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      accountCreatedDate: accountCreatedDate ?? this.accountCreatedDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      themeMode: themeMode ?? this.themeMode,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      fontSize: fontSize ?? this.fontSize,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      cardStyle: cardStyle ?? this.cardStyle,
      enableDynamicColors: enableDynamicColors ?? this.enableDynamicColors,
      languageCode: languageCode ?? this.languageCode,
      weightUnit: weightUnit ?? this.weightUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      currency: currency ?? this.currency,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      aiNotifsEnabled: aiNotifsEnabled ?? this.aiNotifsEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      vaccineAlertsEnabled: vaccineAlertsEnabled ?? this.vaccineAlertsEnabled,
      inventoryAlertsEnabled:
          inventoryAlertsEnabled ?? this.inventoryAlertsEnabled,
      financeAlertsEnabled: financeAlertsEnabled ?? this.financeAlertsEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      notificationSound: notificationSound ?? this.notificationSound,
      vibration: vibration ?? this.vibration,
      aiModel: aiModel ?? this.aiModel,
      responseStyle: responseStyle ?? this.responseStyle,
      aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
      useFarmContext: useFarmContext ?? this.useFarmContext,
      useBatchContext: useBatchContext ?? this.useBatchContext,
      imageAnalysis: imageAnalysis ?? this.imageAnalysis,
      fileAnalysis: fileAnalysis ?? this.fileAnalysis,
      streamingResponses: streamingResponses ?? this.streamingResponses,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
      storageUsedMb: storageUsedMb ?? this.storageUsedMb,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      cloudSyncStatus: cloudSyncStatus ?? this.cloudSyncStatus,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      pinLock: pinLock ?? this.pinLock,
      autoLogoutMinutes: autoLogoutMinutes ?? this.autoLogoutMinutes,
      developerMode: developerMode ?? this.developerMode,
      exportLogsEnabled: exportLogsEnabled ?? this.exportLogsEnabled,
    );
  }
}
