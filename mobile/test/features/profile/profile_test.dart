import 'package:emsidrive_mobile/core/constants/storage_keys.dart';
import 'package:emsidrive_mobile/core/network/authenticated_api.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage.dart';
import 'package:emsidrive_mobile/features/auth/data/token_storage_provider.dart';
import 'package:emsidrive_mobile/features/profile/application/profile_controller.dart';
import 'package:emsidrive_mobile/features/profile/data/http_profile_repository.dart';
import 'package:emsidrive_mobile/features/profile/data/profile_repository.dart';
import 'package:emsidrive_mobile/features/profile/data/profile_repository_provider.dart';
import 'package:emsidrive_mobile/features/profile/domain/student_profile.dart';
import 'package:emsidrive_mobile/core/router/routes.dart';
import 'package:emsidrive_mobile/features/profile/presentation/profile_screen.dart';
import 'package:emsidrive_mobile/shared/widgets/primary_button.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

const alice = StudentProfile(
  id: 'a',
  fullName: 'Alice Etudiante',
  email: 'alice@emsi-edu.ma',
  phoneNumber: '+212612345678',
  major: '2DSI',
  academicYear: '2026-2027',
  preferredCampus: 'TARGA',
  preferredVehicle: 'CAR',
);
const bob = StudentProfile(
  id: 'b',
  fullName: 'Bob Etudiant',
  email: 'bob@emsi-edu.ma',
);

class Profiles implements ProfileRepository {
  StudentProfile current = alice;
  int saves = 0;
  @override
  Future<StudentProfile> loadProfile() async => current;
  @override
  Future<StudentProfile> saveProfile(StudentProfile profile) async {
    saves++;
    return current = profile;
  }
}

class PendingProfiles extends Profiles {
  final first = Completer<StudentProfile>();
  int loads = 0;
  @override
  Future<StudentProfile> loadProfile() =>
      loads++ == 0 ? first.future : Future.value(bob);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('a late response from the previous account cannot replace the current profile', () async {
    final repo = PendingProfiles(),
        tokens = TokenStorage(const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);
    container.read(profileControllerProvider);
    await tokens.saveTokens(accessToken: 'bob', refreshToken: 'bob-refresh');
    expect((await container.read(profileControllerProvider.future)).id, 'b');
    repo.first.complete(alice);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(profileControllerProvider).value!.id, 'b');
  });
  test('loads the current account again after a session change', () async {
    final repo = Profiles(),
        tokens = TokenStorage(const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);
    expect((await container.read(profileControllerProvider.future)).id, 'a');
    repo.current = bob;
    await tokens.saveTokens(accessToken: 'bob', refreshToken: 'bob-refresh');
    expect((await container.read(profileControllerProvider.future)).id, 'b');
    expect(
      container.read(profileControllerProvider).value!.preferredCampus,
      isNull,
    );
  });
  test(
    'profile HTTP updates carry editable fields without account identity',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'alice-token',
      });
      var stored = <String, dynamic>{
        'id': 'a',
        'email': 'alice@emsi-edu.ma',
        ...alice.toUpdateJson(),
      };
      final adapter = FakeHttpAdapter((options) async {
        expect(options.path, '/me');
        expect(options.headers['Authorization'], 'Bearer alice-token');
        if (options.method == 'PUT') {
          stored = {...stored, ...options.data as Map<String, dynamic>};
        }
        return jsonResponse(stored);
      });
      final repo = HttpProfileRepository(
        AuthenticatedApi(
          dioWithAdapter(adapter),
          TokenStorage(const FlutterSecureStorage()),
        ),
      );
      final saved = await repo.saveProfile(alice);
      expect(saved.preferredCampus, 'TARGA');
      expect((await repo.loadProfile()).phoneNumber, alice.phoneNumber);
      final body = adapter.requests.first.data as Map<String, dynamic>;
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('role'), isFalse);
    },
  );
  testWidgets('edits and saves the real profile instead of a demo account', (
    tester,
  ) async {
    final repo = Profiles();
    await pumpEmsiDriveApp(
      tester,
      initialLocation: AppRoutes.profile,
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    expect(find.text(alice.fullName), findsOneWidget);
    expect(find.text(alice.email), findsOneWidget);
    await tester.tap(find.text(l10nOf().profileEdit));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Alice Nouveau Nom',
    );
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(repo.saves, 1);
    expect(repo.current.fullName, 'Alice Nouveau Nom');
    expect(repo.current.preferredCampus, 'TARGA');
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Alice Nouveau Nom'), findsOneWidget);
  });
  testWidgets('invalid profile is not submitted', (tester) async {
    final repo = Profiles();
    await pumpEmsiDriveApp(
      tester,
      initialLocation: AppRoutes.profileEdit,
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.enterText(find.byType(TextFormField).at(0), '   ');
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(find.text(l10nOf().profileNameRequired), findsOneWidget);
  });
}
