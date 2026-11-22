import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_api.dart';
import '../../auth/data/session_id_provider.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(authenticatedApiProvider)),
);

final myReportsProvider = FutureProvider.autoDispose<List<SubmittedReport>>((
  ref,
) {
  ref.watch(sessionIdProvider);
  return ref.watch(reportsRepositoryProvider).mine();
});

class SubmittedReport {
  SubmittedReport.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      category = json['category'] as String,
      status = json['status'] as String,
      created = DateTime.fromMillisecondsSinceEpoch(
        (json['created'] as num).toInt(),
        isUtc: true,
      ).toLocal();
  final String id, category, status;
  final DateTime created;
}

class ReportsRepository {
  ReportsRepository(this._api);
  final AuthenticatedApi _api;

  static String submissionId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<String> submit(String id, Map<String, dynamic> input) async {
    final result = await _api.request<Map<String, dynamic>>(
      'PUT',
      '/reports/$id',
      data: input,
    );
    return result!['id'] as String;
  }

  Future<List<SubmittedReport>> mine() async {
    final rows = await _api.request<List<dynamic>>('GET', '/reports');
    return [
      for (final row in rows!)
        SubmittedReport.fromJson(row as Map<String, dynamic>),
    ];
  }
}
