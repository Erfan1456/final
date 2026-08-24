import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:test/test.dart';

void main() {
  group('SignupRequest.fromJson', () {
    test('parses customer and cleaner roles and trims email', () {
      final customer = SignupRequest.fromJson(<String, dynamic>{
        'email': '  Person@example.com  ',
        'password': 'fifteenCharsPass',
        'role': 'customer',
        'extra': 'ignored',
      });
      expect(customer.email, equals('Person@example.com'));
      expect(customer.password, equals('fifteenCharsPass'));
      expect(customer.role, equals(UserRole.customer));

      final cleaner = SignupRequest.fromJson(<String, dynamic>{
        'email': 'cleaner@example.com',
        'password': 'fifteenCharsPass',
        'role': 'cleaner',
      });
      expect(cleaner.role, equals(UserRole.cleaner));
    });

    test('does not transform the password', () {
      final request = SignupRequest.fromJson(<String, dynamic>{
        'email': 'person@example.com',
        'password': '  fifteenCharsPass  ',
        'role': 'customer',
      });
      expect(request.password, equals('  fifteenCharsPass  '));
    });

    test('rejects admin, unknown, missing, and non-string roles', () {
      Map<String, dynamic> body(Object? role) {
        return <String, dynamic>{
          'email': 'person@example.com',
          'password': 'fifteenCharsPass',
          if (role != _missing) 'role': role,
        };
      }

      expect(
        () => SignupRequest.fromJson(body('admin')),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => SignupRequest.fromJson(body('unknown')),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => SignupRequest.fromJson(body(_missing)),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => SignupRequest.fromJson(body(null)),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => SignupRequest.fromJson(body(1)),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });

    test('rejects missing or non-string email and password', () {
      expect(
        () => SignupRequest.fromJson(<String, dynamic>{
          'password': 'fifteenCharsPass',
          'role': 'customer',
        }),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => SignupRequest.fromJson(<String, dynamic>{
          'email': 'person@example.com',
          'role': 'customer',
        }),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => SignupRequest.fromJson(<String, dynamic>{
          'email': null,
          'password': 'fifteenCharsPass',
          'role': 'customer',
        }),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });
  });

  group('LoginRequest.fromJson', () {
    test('parses and trims email without transforming password', () {
      final request = LoginRequest.fromJson(<String, dynamic>{
        'email': '  Person@example.com  ',
        'password': '  opaque-secret  ',
      });
      expect(request.email, equals('Person@example.com'));
      expect(request.password, equals('  opaque-secret  '));
    });

    test('rejects empty, missing, and non-string passwords', () {
      expect(
        () => LoginRequest.fromJson(<String, dynamic>{
          'email': 'person@example.com',
          'password': '',
        }),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => LoginRequest.fromJson(<String, dynamic>{
          'email': 'person@example.com',
        }),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => LoginRequest.fromJson(<String, dynamic>{
          'email': 'person@example.com',
          'password': 1,
        }),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });
  });

  group('RefreshRequest and LogoutRequest', () {
    test('require a non-empty refresh_token string', () {
      expect(
        RefreshRequest.fromJson(<String, dynamic>{
          'refresh_token': 'opaque-token',
        }).refreshToken,
        equals('opaque-token'),
      );
      expect(
        LogoutRequest.fromJson(<String, dynamic>{
          'refresh_token': 'opaque-token',
        }).refreshToken,
        equals('opaque-token'),
      );
      expect(
        () => RefreshRequest.fromJson(<String, dynamic>{}),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => LogoutRequest.fromJson(<String, dynamic>{'refresh_token': ''}),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => RefreshRequest.fromJson(<String, dynamic>{'refresh_token': null}),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });
  });
}

const Object _missing = Object();
