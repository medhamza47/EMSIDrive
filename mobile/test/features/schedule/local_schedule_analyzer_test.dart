import 'package:dio/dio.dart';
import 'package:emsidrive_mobile/features/schedule/data/local_schedule_analyzer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object> line(
  String text,
  double x,
  double y, {
  double width = 120,
  double confidence = .98,
}) => {
  'text': text,
  'left': x,
  'right': x + width,
  'top': y,
  'bottom': y + 20,
  'confidence': confidence,
};

Map<String, Object> cell(int first, int last, double left, double right) => {
  'first': first,
  'last': last,
  'left': left,
  'right': right,
  'top': 100.0,
  'bottom': 200.0,
};

Map<String, Object> fixture({
  bool merged = true,
  bool measured = true,
  bool explicit = false,
}) => {
  'pages': [
    {
      'lines': [
        line('08:30 - 10:00', 150, 50),
        line('10:15 - 11:45', 350, 50),
        line('12:00 - 13:30', 550, 50),
        line('Lundi', 20, 120, width: 70),
        line('ERP', 150, 120, width: 70),
        if (explicit) line('09:00 - 11:00', 150, 150),
      ],
      'grid': measured
          ? {
              'borders': [100.0, 300.0, 500.0, 700.0],
              'rows': [
                {
                  'cells': [
                    if (merged)
                      cell(0, 1, 100, 500)
                    else ...[
                      cell(0, 0, 100, 300),
                      cell(1, 1, 300, 500),
                    ],
                    cell(2, 2, 500, 700),
                  ],
                },
              ],
            }
          : <String, Object>{},
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final parser = LocalTimetableParser();

  test(
    'a measured merged course spans both printed columns including the break',
    () {
      final result = parser.parse(fixture(), group: 'G1', revision: 4);
      expect(result.slots, hasLength(1));
      expect(result.slots.single.weekday, 1);
      expect(result.slots.single.startTime, '08:30');
      expect(result.slots.single.endTime, '11:45');
      expect(result.revision, 4);
    },
  );

  test('an empty neighboring cell never extends a course', () {
    final result = parser.parse(fixture(merged: false));
    expect(result.slots, hasLength(1));
    expect(result.slots.single.endTime, '10:00');
  });

  test('printed course times take priority over generic column headers', () {
    final result = parser.parse(fixture(explicit: true));
    expect(result.slots.single.startTime, '09:00');
    expect(result.slots.single.endTime, '11:00');
  });

  test(
    'missing grid geometry leaves the end unknown instead of guessing duration',
    () {
      final result = parser.parse(fixture(measured: false));
      expect(result.slots.single.startTime, '08:30');
      expect(result.slots.single.endTime, isNull);
      expect(result.slots.single.complete, isFalse);
      expect(result.slots.single.needsReview, isTrue);
    },
  );

  test('unreadable weekdays cannot create a timetable', () {
    final input = fixture();
    final page = (input['pages'] as List).single as Map;
    (page['lines'] as List).removeWhere((l) => (l as Map)['text'] == 'Lundi');
    expect(() => parser.parse(input), throwsA(isA<LocalScheduleException>()));
  });

  test(
    'each physical weekday is respected even when intermediate days are absent',
    () {
      final input = fixture(measured: false);
      final page = (input['pages'] as List).single as Map;
      (page['lines'] as List).addAll(<Map<String, Object>>[
        line('Vendredi', 20, 250, width: 70),
        line('JAVA', 150, 250),
      ]);
      final result = parser.parse(input);
      expect(result.slots.map((s) => s.weekday), [1, 5]);
    },
  );

  test('empty or pause cells do not become courses', () {
    final input = fixture();
    final page = (input['pages'] as List).single as Map;
    (page['lines'] as List).removeWhere((l) => (l as Map)['text'] == 'ERP');
    (page['lines'] as List).add(line('Pause', 150, 120));
    expect(() => parser.parse(input), throwsA(isA<LocalScheduleException>()));
  });

  test('low confidence content is marked for review', () {
    final input = fixture();
    final page = (input['pages'] as List).single as Map;
    ((page['lines'] as List).last as Map)['confidence'] = .6;
    expect(parser.parse(input).slots.single.needsReview, isTrue);
  });

  test(
    'the phone adapter uses the native channel and preserves PDF source',
    () async {
      const channel = MethodChannel('emsidrive/local_schedule_ocr');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return fixture();
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final bytes = Uint8List.fromList([37, 80, 68, 70, 45]);
      final result = await LocalScheduleAnalyzer().analyze(
        bytes,
        'emploi.pdf',
        'G2',
        3,
        CancelToken(),
      );
      expect(calls.single.method, 'analyze');
      expect((calls.single.arguments as Map)['bytes'], bytes);
      expect(result.source, 'PDF');
      expect(result.preview, isNull);
      expect(result.name, 'G2');
    },
  );

  test('a cancelled job never invokes native inference', () async {
    final cancel = CancelToken()..cancel();
    await expectLater(
      LocalScheduleAnalyzer().analyze(Uint8List(1), 'photo.png', '', 0, cancel),
      throwsA(isA<DioException>()),
    );
  });
}
