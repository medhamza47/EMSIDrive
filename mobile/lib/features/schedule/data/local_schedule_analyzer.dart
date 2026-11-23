import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/schedule_models.dart';

final localScheduleAnalyzerProvider = Provider(
  (ref) => LocalScheduleAnalyzer(),
);

class LocalScheduleException implements Exception {
  const LocalScheduleException(this.code);
  final String code;
}

/// Sends files only to the Android process; this class makes no HTTP requests.
class LocalScheduleAnalyzer {
  static const _channel = MethodChannel('emsidrive/local_schedule_ocr');
  bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<Timetable> analyze(
    Uint8List bytes,
    String filename,
    String group,
    int revision,
    CancelToken cancel,
  ) async {
    if (!available) throw const LocalScheduleException('LOCAL_OCR_UNSUPPORTED');
    var finished = false;
    // A cancellation is also sent to Android. Ignore a late result after cancel.
    cancel.whenCancel.then((_) async {
      if (!finished) {
        try {
          await _channel.invokeMethod<void>('cancel');
        } catch (_) {}
      }
    });
    try {
      if (cancel.isCancelled) throw cancel.cancelError!;
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'analyze',
        {'bytes': bytes},
      );
      if (cancel.isCancelled) throw cancel.cancelError!;
      if (result == null) {
        throw const LocalScheduleException('LOCAL_OCR_FAILED');
      }
      return LocalTimetableParser().parse(
        result,
        group: group,
        revision: revision,
        pdf: filename.toLowerCase().endsWith('.pdf'),
        preview: filename.toLowerCase().endsWith('.pdf') ? null : bytes,
      );
    } on PlatformException catch (error) {
      throw LocalScheduleException(error.code);
    } on MissingPluginException {
      throw const LocalScheduleException('LOCAL_OCR_UNSUPPORTED');
    } finally {
      finished = true;
    }
  }
}

/// Converts measured OCR positions and visible grid borders into course times.
/// It never assumes a fixed lesson duration or extends text into empty cells.
class LocalTimetableParser {
  static final _time = RegExp(r'(?<!\d)([0-2]?\d)\s*[:hH.,]\s*([0-5]\d)(?!\d)');
  static const _days = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  static const _english = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  Timetable parse(
    Map<dynamic, dynamic> result, {
    String group = '',
    int revision = 0,
    bool pdf = false,
    Uint8List? preview,
  }) {
    final slots = <CourseSlot>[];
    final warnings = <String>{
      'Lecture effectuée sur ce téléphone. Vérifiez chaque jour et chaque horaire avant d’enregistrer.',
    };
    var skippedPages = 0;
    for (final rawPage in result['pages'] as List? ?? []) {
      final page = Map<dynamic, dynamic>.from(rawPage as Map);
      final lines = (page['lines'] as List? ?? [])
          .map((l) => _OcrLine(Map<dynamic, dynamic>.from(l as Map)))
          .where((l) => l.text.trim().isNotEmpty && l.confidence >= .25)
          .toList();
      final dayLines = lines.where((l) => _weekday(l.text) != null).toList()
        ..sort((a, b) => a.y.compareTo(b.y));
      if (dayLines.isEmpty) {
        skippedPages++;
        continue;
      }
      final columns = _columns(lines, dayLines.first);
      if (columns.isEmpty) {
        skippedPages++;
        continue;
      }
      // Weekdays belong on the left of time columns, not in a course note.
      final anchors = dayLines.where((l) => l.x < columns.first.x).toList();
      if (anchors.isEmpty) {
        skippedPages++;
        continue;
      }
      final grid = page['grid'] as Map? ?? {};
      final borders = (grid['borders'] as List? ?? [])
          .cast<num>()
          .map((n) => n.toDouble())
          .toList();
      final rows = grid['rows'] as List? ?? [];
      final measured = borders.length == columns.length + 1 && rows.isNotEmpty;
      if (!measured) {
        warnings.add(
          'Les bordures de certaines cellules sont incertaines. Une heure de fin manquante doit être complétée manuellement.',
        );
      }
      final medianGap = anchors.length < 2
          ? 100.0
          : (anchors.last.y - anchors.first.y) / (anchors.length - 1);
      for (var index = 0; index < anchors.length; index++) {
        final day = anchors[index];
        final nextDay = index + 1 < anchors.length ? anchors[index + 1] : null;
        // Prefer the physical row containing the weekday label.
        final rowCells = rows
            .map((r) => (r as Map)['cells'] as List? ?? [])
            .where(
              (cells) =>
                  cells.isNotEmpty &&
                  day.y >= ((cells.first as Map)['top'] as num).toDouble() &&
                  day.y <= ((cells.first as Map)['bottom'] as num).toDouble(),
            )
            .firstOrNull;
        final top = rowCells == null
            ? day.top - day.height
            : ((rowCells.first as Map)['top'] as num).toDouble();
        final bottom = rowCells == null
            ? (nextDay == null
                  ? day.y + medianGap * .75
                  : nextDay.top - nextDay.height * .25)
            : ((rowCells.first as Map)['bottom'] as num).toDouble();
        final content = lines
            .where(
              (l) =>
                  l.y >= top &&
                  l.y < bottom &&
                  l.x > day.right &&
                  _weekday(l.text) == null,
            )
            .toList();
        if (measured && rowCells != null) {
          for (final rawCell in rowCells) {
            final cell = rawCell as Map;
            final first = (cell['first'] as num).toInt(),
                last = (cell['last'] as num).toInt();
            if (first < 0 || last >= columns.length || last < first) continue;
            final left = (cell['left'] as num).toDouble(),
                right = (cell['right'] as num).toDouble();
            final text = content
                .where((l) => l.x > left && l.x < right)
                .toList();
            if (!_occupied(text)) continue;
            final explicit = _explicitTimes(text);
            slots.add(
              CourseSlot(
                weekday: _weekday(day.text),
                startTime: explicit?.$1 ?? columns[first].start,
                endTime: explicit?.$2 ?? columns[last].end,
                needsReview:
                    day.confidence < .85 || text.any((l) => l.confidence < .8),
              ),
            );
          }
        } else {
          // Text coordinates alone cannot prove where a merged cell ends.
          // Preserve its start; ask the user for its end rather than guessing.
          for (var column = 0; column < columns.length; column++) {
            final left = column == 0
                ? day.right
                : (columns[column - 1].x + columns[column].x) / 2;
            final right = column == columns.length - 1
                ? double.infinity
                : (columns[column].x + columns[column + 1].x) / 2;
            final text = content
                .where((l) => l.x > left && l.x < right)
                .toList();
            if (!_occupied(text)) continue;
            final explicit = _explicitTimes(text);
            slots.add(
              CourseSlot(
                weekday: _weekday(day.text),
                startTime: explicit?.$1 ?? columns[column].start,
                endTime: explicit?.$2,
                needsReview: true,
              ),
            );
          }
        }
      }
    }
    if (slots.isEmpty) {
      throw const LocalScheduleException('LOCAL_OCR_NO_TIMETABLE');
    }
    if (skippedPages > 0) {
      warnings.add(
        'Certaines pages n’ont pas pu être interprétées. Comparez le résultat avec votre document.',
      );
    }
    final unique = <String, CourseSlot>{};
    for (final slot in slots) {
      unique['${slot.weekday}/${slot.startTime}/${slot.endTime}'] = slot;
    }
    final sorted = unique.values.toList()..sort(CourseSlot.compare);
    if (sorted.length > 80 || Timetable.overlaps(sorted)) {
      throw const LocalScheduleException('LOCAL_OCR_AMBIGUOUS');
    }
    return Timetable(
      name: group.trim(),
      source: pdf ? 'PDF' : 'IMAGE',
      slots: sorted,
      revision: revision,
      warnings: warnings.toList(),
      preview: preview,
    );
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll('û', 'u')
      .trim();
  static int? _weekday(String text) {
    final normalized = _normalize(text);
    for (var i = 0; i < 7; i++) {
      if (RegExp('^(?:${_days[i]}|${_english[i]})(?:\\b|[0-9])')
          .hasMatch(normalized)) {
        return i + 1;
      }
    }
    return null;
  }

  static List<_OcrColumn> _columns(List<_OcrLine> lines, _OcrLine firstDay) {
    final candidates =
        lines
            .where(
              (l) =>
                  l.y < firstDay.top &&
                  l.x > firstDay.right &&
                  _time.allMatches(l.text).isNotEmpty,
            )
            .toList()
          ..sort((a, b) => a.y.compareTo(b.y));
    final groups = <List<_OcrLine>>[];
    for (final line in candidates) {
      if (groups.isEmpty ||
          (groups.last.first.y - line.y).abs() > line.height * .8) {
        groups.add([line]);
      } else {
        groups.last.add(line);
      }
    }
    final valid = groups
        .where(
          (g) => g.fold(0, (n, l) => n + _time.allMatches(l.text).length) >= 2,
        )
        .toList();
    if (valid.isEmpty) return [];
    valid.sort((a, b) {
      final count = b
          .fold(0, (n, l) => n + _time.allMatches(l.text).length)
          .compareTo(a.fold(0, (n, l) => n + _time.allMatches(l.text).length));
      return count != 0 ? count : b.first.y.compareTo(a.first.y);
    });
    final times = <(String, double)>[];
    for (final line in valid.first) {
      for (final m in _time.allMatches(line.text)) {
        final value = _format(m);
        if (value != null) {
          times.add((
            value,
            line.left +
                (line.right - line.left) *
                    (m.start + m.end) /
                    (2 * line.text.length),
          ));
        }
      }
    }
    times.sort((a, b) => a.$2.compareTo(b.$2));
    if (times.length.isOdd || times.length > 48) return [];
    final columns = <_OcrColumn>[];
    for (var i = 0; i < times.length; i += 2) {
      if (CourseSlot.minutes(times[i].$1)! >=
          CourseSlot.minutes(times[i + 1].$1)!) {
        return [];
      }
      if (columns.isNotEmpty &&
          CourseSlot.minutes(times[i].$1)! <
              CourseSlot.minutes(columns.last.end)!) {
        return [];
      }
      columns.add(
        _OcrColumn(
          times[i].$1,
          times[i + 1].$1,
          (times[i].$2 + times[i + 1].$2) / 2,
        ),
      );
    }
    return columns;
  }

  static String? _format(RegExpMatch match) {
    final hour = int.parse(match[1]!), minute = int.parse(match[2]!);
    return hour < 24
        ? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
        : null;
  }

  static (String, String)? _explicitTimes(List<_OcrLine> lines) {
    for (final line in lines) {
      final matches = _time.allMatches(line.text).toList();
      if (matches.length != 2) continue;
      final a = _format(matches[0]), b = _format(matches[1]);
      if (a != null &&
          b != null &&
          CourseSlot.minutes(a)! < CourseSlot.minutes(b)!) {
        return (a, b);
      }
    }
    return null;
  }

  static bool _occupied(List<_OcrLine> lines) => lines.any(
    (l) =>
        l.confidence >= .5 &&
        l.text.replaceAll(RegExp(r'[\s|_\-—–.]'), '').isNotEmpty &&
        !RegExp(
          r'^(pause|repos|libre|vacances|aucun cours)$',
          caseSensitive: false,
        ).hasMatch(l.text.trim()),
  );
}

class _OcrLine {
  _OcrLine(Map<dynamic, dynamic> json)
    : text = json['text'] as String,
      confidence = (json['confidence'] as num).toDouble(),
      left = (json['left'] as num).toDouble(),
      right = (json['right'] as num).toDouble(),
      top = (json['top'] as num).toDouble(),
      bottom = (json['bottom'] as num).toDouble();
  final String text;
  final double confidence, left, right, top, bottom;
  double get x => (left + right) / 2;
  double get y => (top + bottom) / 2;
  double get height => (bottom - top).clamp(1, double.infinity);
}

class _OcrColumn {
  _OcrColumn(this.start, this.end, this.x);
  final String start, end;
  final double x;
}
