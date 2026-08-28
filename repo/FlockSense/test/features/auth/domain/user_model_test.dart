import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/auth/domain/user_model.dart';

void main() {
  group('UserModel Tests', () {
    final now = DateTime(2026, 8, 28);

    test('serializes and deserializes UserModel round trip', () {
      final user = UserModel(
        uid: 'usr-123',
        name: 'Muthu',
        email: 'muthu@flocksense.com',
        role: 'farm_owner',
        hasCompletedOnboarding: true,
        hasFarm: true,
        activeFarmId: 'farm-001',
        createdAt: now,
        updatedAt: now,
      );

      final json = user.toJson();
      expect(json['uid'], 'usr-123');
      expect(json['role'], 'farm_owner');

      final restored = UserModel.fromJson(json);
      expect(restored.uid, user.uid);
      expect(restored.name, user.name);
      expect(restored.hasFarm, isTrue);
    });

    test('copyWith updates fields without mutating original', () {
      final user = UserModel(
        uid: 'usr-123',
        name: 'Muthu',
        email: 'muthu@flocksense.com',
        role: 'farmer',
        hasCompletedOnboarding: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = user.copyWith(hasCompletedOnboarding: true, activeFarmId: 'farm-99');
      expect(updated.hasCompletedOnboarding, isTrue);
      expect(updated.activeFarmId, 'farm-99');
      expect(user.hasCompletedOnboarding, isFalse);
    });
  });
}
