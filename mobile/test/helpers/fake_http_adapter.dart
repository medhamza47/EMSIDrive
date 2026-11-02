import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Intercepts every request sent through a [Dio] instance.
///
/// Recording the [RequestOptions] lets tests assert on the URL, method and body
/// while the handler controls the answer.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  /// Requests received so far, in call order.
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Builds the JSON [ResponseBody] the real backend would return.
ResponseBody jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

/// Builds a `Dio` wired to [adapter], mirroring the app base URL.
Dio dioWithAdapter(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
    ..httpClientAdapter = adapter;
}
