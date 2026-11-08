import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/schedule_models.dart';
import '../../schedule/presentation/schedule_error.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});
  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsState();
}

class _SuggestionsState extends ConsumerState<SuggestionsScreen> {
  int _commute = 30;
  late Future<List<ScheduleSuggestion>> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(scheduleRepositoryProvider).suggestions(_commute);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FlowPage(
      title: l.searchSharedTrips,
      children: [
        Text(l.timetableMatchingHint),
        Text(l.timetableCommute(_commute)),
        Slider(
          value: _commute.toDouble(),
          min: 5,
          max: 180,
          divisions: 35,
          label: '$_commute',
          onChanged: (v) => setState(() => _commute = v.round()),
          onChangeEnd: (_) => setState(_load),
        ),
        OutlinedButton(
          onPressed: () => setState(_load),
          child: Text(l.timetableReload),
        ),
        FutureBuilder<List<ScheduleSuggestion>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(scheduleError(context, snapshot.error!)),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.scheduleImport),
                    child: Text(l.timetableEdit),
                  ),
                ],
              );
            }
            final matches = snapshot.data!;
            if (matches.isEmpty) return Text(l.timetableNoMatches);
            return Column(
              children: [
                for (final match in matches)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        match.toCampus ? Icons.school : Icons.home_outlined,
                      ),
                      title: Text(match.listing.author),
                      subtitle: Text(
                        '${match.listing.path.title}\n${DateFormat("EEE dd/MM HH:mm", "fr").format(match.listing.path.departure)}\n${match.toCampus ? l.timetableBeforeCourse : l.timetableAfterCourse} ${match.courseTime}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      isThreeLine: true,
                      onTap: () async {
                        await context.push(
                          AppRoutes.listing('offer', match.listing.id),
                        );
                        if (mounted) setState(_load);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
