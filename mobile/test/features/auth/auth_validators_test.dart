import 'package:emsidrive_mobile/features/auth/data/dto/auth_requests.dart';
import 'package:emsidrive_mobile/features/auth/presentation/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  final l10n = l10nOf();
  final validators = AuthValidators(l10n);

  group('email', () {
    test('requires a value', () {
      expect(validators.email(null), l10n.validationEmailRequired);
      expect(validators.email('   '), l10n.validationEmailRequired);
    });

    test('rejects a malformed address', () {
      expect(validators.email('yassine.elamrani'), l10n.validationEmailInvalid);
      expect(validators.email('yassine@'), l10n.validationEmailInvalid);
      expect(validators.email('yassine@emsi-edu'), l10n.validationEmailInvalid);
    });

    test('rejects a non EMSI student domain', () {
      expect(
        validators.email('yassine@gmail.com'),
        l10n.validationEmailDomain(AuthValidators.defaultStudentEmailDomain),
      );
    });

    test('accepts the EMSI student domain, case insensitively', () {
      expect(validators.email('yassine.elamrani@emsi-edu.ma'), isNull);
      expect(validators.email('  Yassine.ElAmrani@EMSI-EDU.MA  '), isNull);
    });
  });

  group('loginPassword', () {
    test('only requires presence', () {
      expect(validators.loginPassword(null), l10n.validationPasswordRequired);
      expect(validators.loginPassword(''), l10n.validationPasswordRequired);
      expect(validators.loginPassword('a'), isNull);
    });
  });

  group('registerPassword', () {
    test('requires a value', () {
      expect(validators.registerPassword(null), l10n.validationPasswordRequired);
      expect(validators.registerPassword(''), l10n.validationPasswordRequired);
    });

    test('enforces the backend bounds', () {
      const min = RegisterRequestDto.passwordMinLength;
      const max = RegisterRequestDto.passwordMaxLength;

      expect(
        validators.registerPassword('a' * (min - 1)),
        l10n.validationPasswordTooShort(min),
      );
      expect(validators.registerPassword('a' * min), isNull);
      expect(validators.registerPassword('a' * max), isNull);
      expect(
        validators.registerPassword('a' * (max + 1)),
        l10n.validationPasswordTooLong(max),
      );
    });
  });

  group('fullName', () {
    test('requires a value', () {
      expect(validators.fullName(null), l10n.validationFullNameRequired);
      expect(validators.fullName('   '), l10n.validationFullNameRequired);
    });

    test('enforces the backend maximum', () {
      const max = RegisterRequestDto.fullNameMaxLength;

      expect(validators.fullName('a' * max), isNull);
      expect(
        validators.fullName('a' * (max + 1)),
        l10n.validationFullNameTooLong(max),
      );
    });
  });

  group('phoneNumber', () {
    test('accepts an empty value since the field is optional', () {
      expect(validators.phoneNumber(null), isNull);
      expect(validators.phoneNumber('   '), isNull);
    });

    test('accepts the backend pattern', () {
      expect(validators.phoneNumber('+212612345678'), isNull);
      expect(validators.phoneNumber('0612345678'), isNull);
      expect(validators.phoneNumber(' 0612345678 '), isNull);
    });

    test('rejects letters and lengths outside the pattern', () {
      expect(validators.phoneNumber('abc'), l10n.validationPhoneNumberInvalid);
      expect(validators.phoneNumber('12345678'), l10n.validationPhoneNumberInvalid);
      expect(validators.phoneNumber('0612345678901234567890'), l10n.validationPhoneNumberInvalid);
    });
  });
}
