import 'dart:async';

import 'package:emsidrive_mobile/core/errors/app_failure.dart';
import 'package:emsidrive_mobile/features/auth/data/auth_repository.dart';
import 'package:emsidrive_mobile/features/auth/data/dto/auth_response_dto.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a late login response cannot undo sign-out', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final pending = Completer<AuthResponseDto>();
    final tokens = TokenStorage(const FlutterSecureStorage());
    addTearDown(tokens.dispose);
    final repository = AuthRepository(
      api: FakeAuthApi(pending: pending),
      tokenStorage: tokens,
    );
    final result = expectLater(
      repository.login(email: 'old@emsi-edu.ma', password: 'DemoPass123!'),
      throwsA(isA<UnauthorizedFailure>()),
    );
    await repository.signOut();
    pending.complete(authResponse());
    await result;
    expect(await tokens.readAccessToken(), isNull);
    expect(await tokens.readRefreshToken(), isNull);
  });
}
