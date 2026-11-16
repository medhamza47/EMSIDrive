import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_models.dart';
import '../application/saved_timetable_provider.dart';
import '../application/import_job_provider.dart';
import 'import_job_card.dart';
import 'schedule_error.dart';

class ScheduleImportScreen extends ConsumerStatefulWidget {
  const ScheduleImportScreen({super.key});
  @override
  ConsumerState<ScheduleImportScreen> createState() => _ImportState();
}

class _ImportState extends ConsumerState<ScheduleImportScreen> {
  final _group = TextEditingController();
  CancelToken _cancel = CancelToken();
  Timetable? _current;
  Uint8List? _bytes;
  String? _filename;
  Object? _error;
  bool _loading = true, _busy = false, _loaded = false, _analyzing = false;
  ScheduleRepository get _repository => ref.read(scheduleRepositoryProvider);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _loaded = false;
    });
    try {
      final result = await _repository.current();
      if (mounted) {
        setState(() {
          _current = result;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _cancel.cancel();
    _group.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      Uint8List? bytes;
      String? name;
      if (camera) {
        final file = await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxWidth: 2600,
          maxHeight: 2600,
          imageQuality: 95,
        );
        if (file != null) {
          bytes = await file.readAsBytes();
          name = file.name;
        }
      } else {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        );
        if (file != null) {
          if ((await file.length() ?? 0) > 8 * 1024 * 1024) {
            throw const ScheduleFileTooLarge();
          }
          bytes = await file.readAsBytes();
          name = file.name;
        }
      }
      if (bytes != null && bytes.length > 8 * 1024 * 1024) {
        throw const ScheduleFileTooLarge();
      }
      if (mounted && bytes != null) {
        setState(() {
          _bytes = bytes;
          _filename = name;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(Timetable draft) async {
    await context.push(AppRoutes.scheduleSlots, extra: draft);
    if (mounted) await _load();
  }

  Future<void> _analyze() async {
    _cancel = CancelToken();
    setState(() {
      _analyzing = true;
      _busy = true;
      _error = null;
    });
    try {
      await _repository.startImport(
        _bytes!,
        _filename!,
        _group.text.trim(),
        _current?.revision ?? 0,
        _cancel,
      );
      if (mounted) {
        ref.invalidate(scheduleImportJobProvider);
      }
    } catch (e) {
      if (mounted && !_cancel.isCancelled) setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _analyzing = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.timetableDelete),
        content: Text(l.timetableDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.timetableCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.timetableDelete),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.delete();
      ref.invalidate(savedTimetableProvider);
      if (mounted) setState(() => _current = null);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pending =
        ref.watch(scheduleImportJobProvider).asData?.value?.pending ?? false;
    final enabled = !_loading && !_busy && _loaded && !pending;
    return FlowPage(
      title: l.scheduleTitle,
      children: [
        const ImportJobCard(),
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                Text(
                  l.timetableHero,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(l.timetableImportHint),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.upload_file, size: 18),
                      label: Text(l.timetableStepImport),
                    ),
                    Chip(
                      avatar: const Icon(Icons.event_available, size: 18),
                      label: Text(l.timetableStepReview),
                    ),
                    Chip(
                      avatar: const Icon(Icons.directions_car, size: 18),
                      label: Text(l.timetableStepRide),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_analyzing && _busy) ...[
          const LinearProgressIndicator(),
          Text(l.importUploading),
          TextButton.icon(
            onPressed: () => _cancel.cancel(),
            icon: const Icon(Icons.close),
            label: Text(l.timetableCancel),
          ),
        ],
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(
            scheduleError(context, _error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _busy ? null : _load,
            child: Text(l.timetableReload),
          ),
        ],
        if (_current != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _current!.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${Timetable.date(_current!.validFrom!)} — ${Timetable.date(_current!.validUntil!)}',
                  ),
                  TextButton(
                    onPressed: enabled ? () => _edit(_current!) : null,
                    child: Text(l.timetableEdit),
                  ),
                  FilledButton(
                    onPressed: enabled
                        ? () => context.push(AppRoutes.suggestions)
                        : null,
                    child: Text(l.searchSharedTrips),
                  ),
                  TextButton(
                    onPressed: enabled ? _delete : null,
                    child: Text(l.timetableDelete),
                  ),
                ],
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: enabled ? () => _pick(false) : null,
              child: Text(l.chooseFile),
            ),
            OutlinedButton(
              onPressed: enabled ? () => _pick(true) : null,
              child: Text(l.takePhoto),
            ),
          ],
        ),
        if (_bytes != null) ...[
          ListTile(
            title: Text(_filename!),
            trailing: IconButton(
              tooltip: l.removeFile,
              onPressed: enabled
                  ? () => setState(() {
                      _bytes = null;
                      _filename = null;
                    })
                  : null,
              icon: const Icon(Icons.close),
            ),
          ),
          if (!_filename!.toLowerCase().endsWith('.pdf'))
            Image.memory(
              _bytes!,
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Text(l.timetableFileError),
            ),
        ],
        TextField(
          controller: _group,
          enabled: enabled,
          maxLength: 120,
          decoration: InputDecoration(
            labelText: l.timetableGroup,
            helperText: l.timetableGroupHint,
            helperMaxLines: 3,
          ),
        ),
        Text(l.timetableAiNotice),
        PrimaryButton(
          label: l.analyzeSchedule,
          isLoading: _busy,
          onPressed: enabled && _bytes != null ? _analyze : null,
        ),
        TextButton(
          onPressed: enabled
              ? () => _edit(
                  Timetable(
                    name: '',
                    source: 'MANUAL',
                    slots: const [],
                    revision: _current?.revision ?? 0,
                  ),
                )
              : null,
          child: Text(l.timetableManual),
        ),
      ],
    );
  }
}

class ScheduleSlotsScreen extends ConsumerStatefulWidget {
  const ScheduleSlotsScreen({this.initial, super.key});
  final Timetable? initial;
  @override
  ConsumerState<ScheduleSlotsScreen> createState() => _SlotsState();
}

class _SlotsState extends ConsumerState<ScheduleSlotsScreen> {
  final _name = TextEditingController();
  Timetable? _draft;
  List<CourseSlot> _slots = [];
  DateTime? _from, _until;
  Object? _error;
  bool _loading = true, _saving = false, _confirmed = false;
  bool _suggestedDates = false;
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final draft =
          widget.initial ??
          await ref.read(scheduleRepositoryProvider).current();
      if (mounted) {
        setState(() {
          _draft = draft;
          _slots = [...?draft?.slots]..sort(CourseSlot.compare);
          _name.text = (draft?.name.isNotEmpty ?? false)
              ? draft!.name
              : AppLocalizations.of(context).scheduleTitle;
          final now = DateTime.now();
          _suggestedDates =
              draft != null &&
              draft.validFrom == null &&
              draft.validUntil == null;
          _from =
              draft?.validFrom ??
              (_suggestedDates ? DateTime(now.year, now.month, now.day) : null);
          _until =
              draft?.validUntil ??
              (_suggestedDates
                  ? DateTime(_from!.year, _from!.month, _from!.day + 6)
                  : null);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _slots.isNotEmpty &&
      _slots.length <= 80 &&
      _slots.every((s) => s.complete) &&
      !Timetable.overlaps(_slots) &&
      _from != null &&
      _until != null &&
      !_until!.isBefore(_from!) &&
      !_until!.isAfter(DateTime(_from!.year + 1, _from!.month, _from!.day));

  List<String> _validationIssues(AppLocalizations l) => [
    if (_name.text.trim().isEmpty) l.timetableMissingName,
    if (_slots.isEmpty) l.timetableNoSessions,
    if (_slots.length > 80) l.timetableTooManySessions,
    if (_slots.any((s) => !s.complete))
      l.timetableMissingTimes(_slots.where((s) => !s.complete).length),
    if (Timetable.overlaps(_slots)) l.timetableOverlap,
    if (_from == null ||
        _until == null ||
        _until!.isBefore(_from!) ||
        _until!.isAfter(DateTime(_from!.year + 1, _from!.month, _from!.day)))
      l.timetableInvalidDates,
  ];
  void _useWeekPeriod() {
    final now = DateTime.now();
    setState(() {
      _from = DateTime(now.year, now.month, now.day);
      _until = DateTime(now.year, now.month, now.day + 6);
      _suggestedDates = true;
      _confirmed = false;
    });
  }

  Future<void> _date(bool start) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _from : _until) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (mounted && selected != null) {
      setState(() {
        if (start) {
          _from = selected;
        } else {
          _until = selected;
        }
        _suggestedDates = false;
        _confirmed = false;
      });
    }
  }

  Future<void> _edit(int? index) async {
    final slot = await showDialog<CourseSlot>(
      context: context,
      builder: (_) =>
          _SlotDialog(slot: index == null ? const CourseSlot() : _slots[index]),
    );
    if (!mounted || slot == null) return;
    setState(() {
      if (index == null) {
        _slots.add(slot);
      } else {
        _slots[index] = slot;
      }
      _slots.sort(CourseSlot.compare);
      _confirmed = false;
    });
  }

  Future<void> _save({bool reserve = false}) async {
    if (!_valid || !_confirmed || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(scheduleRepositoryProvider)
          .save(
            Timetable(
              name: _name.text,
              source: _draft!.source,
              slots: _slots,
              validFrom: _from,
              validUntil: _until,
              revision: _draft!.revision,
              analysisJobId: _draft!.analysisJobId,
            ),
          );
      ref.invalidate(savedTimetableProvider);
      ref.invalidate(scheduleImportJobProvider);
      if (mounted) {
        if (reserve) {
          context.go(AppRoutes.suggestions);
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.planning);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FlowPage(
      title: l.slotsTitle,
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Text(
            scheduleError(context, _error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (!_loading && _draft == null)
          TextButton(
            onPressed: () => context.go(AppRoutes.scheduleImport),
            child: Text(l.scheduleImportTitle),
          ),
        if (_draft != null) ...[
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  Text(
                    l.presenceDigitalTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final day in Timetable(
                    name: '',
                    source: _draft!.source,
                    slots: _slots,
                  ).attendance)
                    Text(
                      '${timetableDays(l)[day.weekday - 1]} · ${l.presenceArrival(day.arrival)} · ${l.presenceLeaving(day.leaving)}',
                    ),
                ],
              ),
            ),
          ),
          for (final warning in _draft!.warnings) Text(warning),
          if (_draft!.preview != null)
            OutlinedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog.fullscreen(
                  child: Scaffold(
                    appBar: AppBar(title: Text(l.timetableOriginal)),
                    body: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 6,
                      child: Center(child: Image.memory(_draft!.preview!)),
                    ),
                  ),
                ),
              ),
              child: Text(l.timetableOriginal),
            ),
          TextField(
            controller: _name,
            enabled: !_saving,
            maxLength: 120,
            decoration: InputDecoration(labelText: l.timetableName),
            onChanged: (_) => setState(() => _confirmed = false),
          ),
          if (_suggestedDates) Text(l.timetableSuggestedDates),
          TextButton.icon(
            onPressed: _saving ? null : _useWeekPeriod,
            icon: const Icon(Icons.date_range),
            label: Text(l.timetableUseWeekPeriod),
          ),
          OutlinedButton(
            onPressed: _saving ? null : () => _date(true),
            child: Text(
              '${l.timetableFrom} : ${_from == null ? '—' : Timetable.date(_from!)}',
            ),
          ),
          OutlinedButton(
            onPressed: _saving ? null : () => _date(false),
            child: Text(
              '${l.timetableUntil} : ${_until == null ? '—' : Timetable.date(_until!)}',
            ),
          ),
          for (final (index, slot) in _slots.indexed)
            Card(
              color: !slot.complete
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: Icon(
                  (slot.needsReview && !_confirmed) || !slot.complete
                      ? Icons.warning_amber
                      : Icons.event_available,
                ),
                title: Text(
                  slot.weekday == null
                      ? l.timetableUnknown
                      : timetableDays(l)[slot.weekday! - 1],
                ),
                subtitle: Text(
                  '${slot.startTime ?? "?"}–${slot.endTime ?? "?"}${(slot.needsReview && !_confirmed) || !slot.complete ? "\n${l.timetableNeedsReview}" : ""}',
                ),
                onTap: _saving ? null : () => _edit(index),
                trailing: IconButton(
                  tooltip: l.timetableRemoveCourse,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _slots.removeAt(index);
                          _confirmed = false;
                        }),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _saving || _slots.length >= 80
                ? null
                : () => _edit(null),
            icon: const Icon(Icons.add),
            label: Text(l.timetableAddCourse),
          ),
          for (final issue in _validationIssues(l))
            Text(
              issue,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.timetableConfirm),
            value: _confirmed,
            onChanged: _saving || !_valid
                ? null
                : (value) => setState(() => _confirmed = value!),
          ),
          PrimaryButton(
            label: l.timetableSaveAndRide,
            isLoading: _saving,
            onPressed: _valid && _confirmed && !_saving
                ? () => _save(reserve: true)
                : null,
          ),
          TextButton(
            onPressed: _valid && _confirmed && !_saving ? () => _save() : null,
            child: Text(l.timetableSave),
          ),
        ],
      ],
    );
  }
}

List<String> timetableDays(AppLocalizations l) => [
  l.monday,
  l.tuesday,
  l.wednesday,
  l.timetableThursday,
  l.timetableFriday,
  l.timetableSaturday,
  l.timetableSunday,
];

class _SlotDialog extends StatefulWidget {
  const _SlotDialog({required this.slot});
  final CourseSlot slot;
  @override
  State<_SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<_SlotDialog> {
  final _form = GlobalKey<FormState>();
  late final _start = TextEditingController(text: widget.slot.startTime);
  late final _end = TextEditingController(text: widget.slot.endTime);
  late int? _day = widget.slot.weekday;
  @override
  void dispose() {
    for (final c in [_start, _end]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String? time(String? value) =>
        CourseSlot.minutes(value) == null ? l.timetableTimeInvalid : null;
    return AlertDialog(
      title: Text(l.timetableCourse),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: InputDecoration(labelText: l.timetableDay),
                items: [
                  for (final (i, day) in timetableDays(l).indexed)
                    DropdownMenuItem(value: i + 1, child: Text(day)),
                ],
                onChanged: (v) => setState(() => _day = v),
                validator: (v) => v == null ? l.timetableRequired : null,
              ),
              TextFormField(
                controller: _start,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: l.timetableStart),
                validator: time,
              ),
              TextFormField(
                controller: _end,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: l.timetableEnd),
                validator: (v) =>
                    time(v) ??
                    (CourseSlot.minutes(_start.text) != null &&
                            CourseSlot.minutes(v)! <=
                                CourseSlot.minutes(_start.text)!
                        ? l.timetableTimeInvalid
                        : null),
              ),
              if (_day == DateTime.friday)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _start.text = '15:00';
                  }),
                  icon: const Icon(Icons.schedule),
                  label: Text(l.fridayStartAt15),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.timetableCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(
                context,
                CourseSlot(
                  weekday: _day,
                  startTime: _start.text,
                  endTime: _end.text,
                ),
              );
            }
          },
          child: Text(l.timetableValidateCourse),
        ),
      ],
    );
  }
}
