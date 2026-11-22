import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/data/session_id_provider.dart';
import '../data/reports_repository.dart';

String reportCategory(AppLocalizations l, String value) => switch (value) {
  'HARASSMENT' => l.reportHarassment,
  'NO_SHOW' => l.reportNoShow,
  'UNSAFE_DRIVING' => l.reportUnsafeDriving,
  'FAKE_PROFILE' => l.reportFakeProfile,
  'PAYMENT' => l.reportPayment,
  _ => l.reportOther,
};

String reportStatus(AppLocalizations l, String value) => switch (value) {
  'UNDER_REVIEW' => l.reportUnderReview,
  'RESOLVED' => l.reportResolved,
  'DISMISSED' => l.reportDismissed,
  _ => l.reportOpen,
};

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({required this.contextData, super.key});
  final Map<String, dynamic> contextData;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _submission = ReportsRepository.submissionId();
  String _category = 'OTHER';
  bool _busy = false;
  bool _attempted = false;
  String? _error, _reference;
  late final int _originSession;

  @override
  void initState() {
    super.initState();
    _originSession = ref.read(sessionIdProvider);
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy ||
        ref.read(sessionIdProvider) != _originSession ||
        !_form.currentState!.validate()) {
      return;
    }
    final session = ref.read(sessionIdProvider);
    setState(() {
      _busy = true;
      _attempted = true;
      _error = null;
    });
    try {
      final id = await ref.read(reportsRepositoryProvider).submit(_submission, {
        ...widget.contextData,
        'category': _category,
        'description': _description.text.trim(),
      });
      if (!mounted || session != ref.read(sessionIdProvider)) return;
      ref.invalidate(myReportsProvider);
      setState(() => _reference = id);
    } catch (_) {
      if (mounted && session == ref.read(sessionIdProvider)) {
        setState(() => _error = AppLocalizations.of(context).reportFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (ref.watch(sessionIdProvider) != _originSession) {
      return FlowPage(
        title: l.reportTitle,
        children: [
          Text(l.reportSessionChanged),
          PrimaryButton(
            label: l.reportClose,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }
    return PopScope(
      canPop: !_busy,
      child: FlowPage(
        title: l.reportTitle,
        children: [
          if (_reference != null) ...[
            const Icon(Icons.check_circle_outline, size: 56),
            Text(l.reportSent, style: Theme.of(context).textTheme.titleLarge),
            Text(l.reportSentHint),
            SelectableText(l.reportReference(_reference!)),
            PrimaryButton(
              label: l.reportClose,
              onPressed: () => Navigator.pop(context),
            ),
          ] else ...[
            Text(l.reportHint),
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.reportCategory),
                    items: [
                      for (final category in [
                        'HARASSMENT',
                        'NO_SHOW',
                        'UNSAFE_DRIVING',
                        'FAKE_PROFILE',
                        'PAYMENT',
                        'OTHER',
                      ])
                        DropdownMenuItem(
                          value: category,
                          child: Text(reportCategory(l, category)),
                        ),
                    ],
                    onChanged: _attempted
                        ? null
                        : (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _description,
                    readOnly: _attempted,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: l.reportDescription,
                      hintText: l.reportDescriptionHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l.reportRequired;
                      }
                      if (value.trim().length > 1000) return l.reportTooLong;
                      return null;
                    },
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_attempted && _error != null) Text(l.reportRetryHint),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _attempted ? l.retryLabel : l.reportSend,
                    icon: Icons.flag_outlined,
                    isLoading: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return FlowPage(
      title: l.myReports,
      children: [
        Text(l.myReportsHint),
        ref
            .watch(myReportsProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(myReportsProvider),
                child: Text(l.retryLabel),
              ),
              data: (rows) => rows.isEmpty
                  ? Text(l.myReportsEmpty)
                  : Column(
                      children: [
                        for (final row in rows)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.flag_outlined),
                              title: Text(reportCategory(l, row.category)),
                              subtitle: Text(
                                '${DateFormat.yMMMd('fr').format(row.created)}\n${l.reportReference(row.id)}',
                              ),
                              trailing: Text(reportStatus(l, row.status)),
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }
}
