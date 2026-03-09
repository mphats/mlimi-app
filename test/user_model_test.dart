import 'package:flutter_test/flutter_test.dart';
import 'package:mulimi/core/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    group('fromJson Tests', () {
      test('UserModel can be created from valid JSON', () {
        final json = {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'role': 'FARMER',
          'first_name': 'Test',
          'last_name': 'User',
          'is_active': true,
          'date_joined': '2023-01-01T00:00:00Z',
        };

        final user = UserModel.fromJson(json);
        expect(user.id, 1);
        expect(user.username, 'testuser');
        expect(user.email, 'test@example.com');
        expect(user.role, 'FARMER');
        expect(user.firstName, 'Test');
        expect(user.lastName, 'User');
        expect(user.isActive, isTrue);
        expect(user.dateJoined, isNotNull);
      });

      test('UserModel handles string ID correctly', () {
        final json = {
          'id': '1',
          'username': 'testuser',
          'email': 'test@example.com',
          'role': 'FARMER',
        };

        final user = UserModel.fromJson(json);
        expect(user.id, 1);
      });

      test('UserModel handles invalid string ID gracefully', () {
        final json = {
          'id': 'invalid',
          'username': 'testuser',
          'email': 'test@example.com',
          'role': 'FARMER',
        };

        final user = UserModel.fromJson(json);
        expect(user.id, 0);
      });

      test('UserModel handles missing optional fields', () {
        final json = {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'role': 'FARMER',
        };

        final user = UserModel.fromJson(json);
        expect(user.id, 1);
        expect(user.username, 'testuser');
        expect(user.email, 'test@example.com');
        expect(user.role, 'FARMER');
        expect(user.firstName, isNull);
        expect(user.lastName, isNull);
        expect(user.isActive, isTrue);
      });
    });

    group('UserModel Methods Tests', () {
      late UserModel user;

      setUp(() {
        user = UserModel(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          role: 'FARMER',
          firstName: 'Test',
          lastName: 'User',
        );
      });

      test('displayName returns full name when available', () {
        expect(user.displayName, 'Test User');
      });

      test('displayName returns username when full name not available', () {
        final userWithoutName = UserModel(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          role: 'FARMER',
        );
        expect(userWithoutName.displayName, 'testuser');
      });

      test('initials returns correct initials', () {
        expect(user.initials, 'TU');
      });

      test('initials handles single character username', () {
        final userWithShortName = UserModel(
          id: 1,
          username: 'a',
          email: 'test@example.com',
          role: 'FARMER',
        );
        expect(userWithShortName.initials, 'A');
      });

      test('initials handles empty username', () {
        final userWithEmptyName = UserModel(
          id: 1,
          username: '',
          email: 'test@example.com',
          role: 'FARMER',
        );
        expect(userWithEmptyName.initials, 'UU');
      });

      test('roleDisplayName returns correct display name', () {
        expect(user.roleDisplayName, 'Farmer');
        
        final adminUser = UserModel(
          id: 1,
          username: 'admin',
          email: 'admin@example.com',
          role: 'ADMIN',
        );
        expect(adminUser.roleDisplayName, 'Admin');
      });

      test('copyWith creates new instance with updated values', () {
        final updatedUser = user.copyWith(firstName: 'Updated');
        expect(updatedUser.firstName, 'Updated');
        expect(updatedUser.lastName, 'User'); // Unchanged
        expect(updatedUser.id, 1); // Unchanged
      });

      test('equality operator works correctly', () {
        final sameUser = UserModel(
          id: 1,
          username: 'different',
          email: 'different@example.com',
          role: 'TRADER',
        );
        expect(user, equals(sameUser)); // Same ID
        
        final differentUser = UserModel(
          id: 2,
          username: 'testuser',
          email: 'test@example.com',
          role: 'FARMER',
        );
        expect(user, isNot(equals(differentUser))); // Different ID
      });
    });
  });
}