import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/schedule_models.dart';
part 'schedule_repository.g.dart';

@Riverpod(keepAlive: true)
ScheduleRepository scheduleRepository(Ref ref) =>
    HttpScheduleRepository(ref.watch(authenticatedApiProvider));

abstract interface class ScheduleRepository {
  Future<Timetable?> current();
  Future<Timetable> analyze(
    Uint8List bytes,
    String filename,
    String group,
    int revision,
    CancelToken cancel,
  );
  Future<Timetable> save(Timetable timetable);
  Future<void> delete();
  Future<List<ScheduleSuggestion>> suggestions(int commuteMinutes);
}

class HttpScheduleRepository implements ScheduleRepository {
  HttpScheduleRepository(this._api);
  final AuthenticatedApi _api;
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  @override
  Future<Timetable?> current() async {
    try {
      return await _guard(
        () async => Timetable.fromJson(
          (await _api.request<Map<String, dynamic>>(
            'GET',
            '/schedules/current',
          ))!,
        ),
      );
    } on ApiFailure catch (e) {
      if (e.code == 'SCHEDULE_NOT_FOUND') return null;
      rethrow;
    }
  }

  @override
  Future<Timetable> analyze(
    Uint8List bytes,
    String filename,
    String group,
    int revision,
    CancelToken cancel,
  ) => _guard(() async {
    final data = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'group': group,
    });
    final json = await _api.request<Map<String, dynamic>>(
      'POST',
      '/schedules/analyze',
      data: data,
      timeout: const Duration(seconds: 100),
      cancelToken: cancel,
    );
    return Timetable.fromJson(
      json!,
      revision: revision,
      preview: filename.toLowerCase().endsWith('.pdf') ? null : bytes,
    );
  });
  @override
  Future<Timetable> save(Timetable timetable) => _guard(
    () async => Timetable.fromJson(
      (await _api.request<Map<String, dynamic>>(
        'PUT',
        '/schedules/current',
        data: timetable.toJson(),
      ))!,
    ),
  );
  @override
  Future<void> delete() => _guard(() async {
    await _api.request<Object>('DELETE', '/schedules/current');
  });
  @override
  Future<List<ScheduleSuggestion>> suggestions(int commuteMinutes) => _guard(
    () async =>
        (await _api.request<List<dynamic>>(
              'GET',
              '/schedules/suggestions',
              query: {'commuteMinutes': commuteMinutes},
            ))!
            .map((s) => ScheduleSuggestion.fromJson(s as Map<String, dynamic>))
            .toList(),
  );
}
