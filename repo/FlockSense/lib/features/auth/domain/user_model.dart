class UserModel {
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.hasCompletedOnboarding,
    this.hasFarm = false,
    this.activeFarmId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool hasCompletedOnboarding;
  final bool hasFarm;
  final String? activeFarmId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'farmer',
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      hasFarm: json['hasFarm'] as bool? ?? false,
      activeFarmId: json['activeFarmId'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasFarm': hasFarm,
      'activeFarmId': activeFarmId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    bool? hasCompletedOnboarding,
    bool? hasFarm,
    String? activeFarmId,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasFarm: hasFarm ?? this.hasFarm,
      activeFarmId: activeFarmId ?? this.activeFarmId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
