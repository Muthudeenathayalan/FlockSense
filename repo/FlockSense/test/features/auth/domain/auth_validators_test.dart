import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/auth/domain/auth_validators.dart';

void main() {
  group('AuthValidators Tests', () {
    test('validates email addresses properly', () {
      expect(AuthValidators.validateEmail('user@flocksense.com'), isNull);
      expect(AuthValidators.validateEmail(''), 'Email is required');
      expect(AuthValidators.validateEmail('invalid-email'), 'Please enter a valid email address');
    });

    test('validates password length properly', () {
      expect(AuthValidators.validatePassword('Secret123'), isNull);
      expect(AuthValidators.validatePassword(''), 'Password is required');
      expect(AuthValidators.validatePassword('12345'), 'Password must be at least 6 characters');
    });

    test('validates name length properly', () {
      expect(AuthValidators.validateName('Farmer John'), isNull);
      expect(AuthValidators.validateName(''), 'Name is required');
      expect(AuthValidators.validateName('J'), 'Name must be at least 2 characters');
    });

    test('validates phone numbers properly', () {
      expect(AuthValidators.validatePhone('+91 9876543210'), isNull);
      expect(AuthValidators.validatePhone(''), isNull); // Optional
      expect(AuthValidators.validatePhone('abc'), 'Please enter a valid phone number');
    });
  });
}
