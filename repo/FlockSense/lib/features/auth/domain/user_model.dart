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
}
