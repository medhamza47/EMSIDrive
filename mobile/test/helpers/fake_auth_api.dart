import 'dart:async';

import 'package:emsidrive_mobile/features/auth/data/auth_api.dart';
import 'package:emsidrive_mobile/features/auth/data/dto/auth_requests.dart';
import 'package:emsidrive_mobile/features/auth/data/dto/auth_response_dto.dart';
import 'package:emsidrive_mobile/features/auth/data/dto/user_dto.dart';
import 'package:emsidrive_mobile/features/auth/domain/auth_user.dart';

/// Sample access token returned by [authResponse].
const String sampleAccessToken = 'access-token-value';

/// Sample refresh token returned by [authResponse].
const String sampleRefreshToken = 'refresh-token-value';

/// Payload shaped exactly like the backend `AuthResponse`.
Map<String, dynamic> authResponseJson({
  String accessToken = sampleAccessToken,
  String refreshToken = sampleRefreshToken,
  int expiresIn = 900,
  String role = 'STUDENT',
  bool enabled = true,
}) {
  return <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenType': 'Bearer',
    'expiresIn': expiresIn,
    'user': <String, dynamic>{
      'id': '3f1c6f3e-0f0e-4b6d-9b0a-1c2d3e4f5a6b',
      'email': 'yassine.elamrani@emsi-edu.ma',
      'fullName': 'Yassine El Amrani',
      'phoneNumber': '+212612345678',
      'role': role,
      'enabled': enabled,
    },
  };
}

/// Domain response matching [authResponseJson].
AuthResponseDto authResponse() => AuthResponseDto.fromJson(authResponseJson());

/// Payload shaped exactly like the backend `ApiError`, `details` included.
Map<String, dynamic> apiErrorJson({
  required int status,
  required String code,
  required String message,
  List<Map<String, String>> details = const <Map<String, String>>[],
}) {
  return <String, dynamic>{
    'timestamp': '2024-01-01T10:00:00Z',
    'status': status,
    'code': code,
    'message': message,
    if (details.isNotEmpty) 'details': details,
  };
}

/// Stub [AuthApi] returning canned responses, errors or a pending future.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({this.response, this.error, this.pending});

  /// Response returned when neither [error] nor [pending] is set.
  final AuthResponseDto? response;

  /// Error thrown instead of answering, usually an `AppFailure` or a raw error.
  final Object? error;

  /// When set, every call waits on it so tests can observe the loading state.
  final Completer<AuthResponseDto>? pending;

  /// Login bodies received, in call order.
  final List<LoginRequestDto> loginRequests = <LoginRequestDto>[];

  /// Register bodies received, in call order.
  final List<RegisterRequestDto> registerRequests = <RegisterRequestDto>[];

  @override
  Future<AuthResponseDto> login(LoginRequestDto request) {
    loginRequests.add(request);
    return _answer();
  }

  @override
  Future<AuthResponseDto> register(RegisterRequestDto request) {
    registerRequests.add(request);
    return _answer();
  }

  Future<AuthResponseDto> _answer() {
    final pendingCall = pending;
    if (pendingCall != null) {
      return pendingCall.future;
    }
    final failure = error;
    if (failure != null) {
      return Future<AuthResponseDto>.error(failure);
    }
    return Future<AuthResponseDto>.value(response ?? authResponse());
  }
}

/// Expected domain user for [authResponseJson] without overrides.
const AuthUser sampleStudent = AuthUser(
  id: '3f1c6f3e-0f0e-4b6d-9b0a-1c2d3e4f5a6b',
  email: 'yassine.elamrani@emsi-edu.ma',
  fullName: 'Yassine El Amrani',
  phoneNumber: '+212612345678',
  role: UserRole.student,
  enabled: true,
);

/// Convenience builder for a [UserDto] used in DTO level tests.
UserDto userDto() => UserDto.fromJson(
  authResponseJson()['user'] as Map<String, dynamic>,
);
