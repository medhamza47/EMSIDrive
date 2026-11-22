import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/form_section.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/data/session_id_provider.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/presentation/profile_edit_screen.dart';
import '../data/marketplace_api.dart';
import '../domain/marketplace_models.dart';
import 'marketplace_screens.dart';
import 'ride_lifecycle.dart';

class TripSummaryScreen extends ConsumerStatefulWidget {
  const TripSummaryScreen({required this.id, super.key});
  final String id;

  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  late final int _session = ref.read(sessionIdProvider);
  late Future<Map<String, dynamic>> _summary = _load();
  final _comment = TextEditingController();
  final _total = TextEditingController();
  final _costForm = GlobalKey<FormState>();
  int _score = 5;
  bool _saving = false;
  String? _error;

  Future<Map<String, dynamic>> _load() =>
      ref.read(marketplaceApiProvider).summary(widget.id);

  @override
  void dispose() {
    _comment.dispose();
    _total.dispose();
    super.dispose();
  }

  void _refresh() {
    final summary = _load();
    setState(() {
      _summary = summary;
    });
  }

  Future<void> _submit({required bool review}) async {
    if (_saving || ref.read(sessionIdProvider) != _session) return;
    if (!review) {
      if (!_costForm.currentState!.validate()) return;
      if (!await confirmRideAction(
            context,
            AppLocalizations.of(context).tripCostConfirm,
          ) ||
          !mounted) {
        return;
      }
    }
    if (!mounted || ref.read(sessionIdProvider) != _session) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ref.read(marketplaceApiProvider);
      if (review) {
        await api.review(widget.id, _score, _comment.text.trim());
      } else {
        await api.costs(widget.id, _total.text.trim().replaceAll(',', '.'));
      }
      if (!mounted || ref.read(sessionIdProvider) != _session) return;
      ref.invalidate(profileControllerProvider);
      _refresh();
    } catch (error) {
      if (mounted && ref.read(sessionIdProvider) == _session) {
        setState(
          () => _error = profileFailure(
            AppLocalizations.of(context),
            ErrorMapper.map(error),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (ref.watch(sessionIdProvider) != _session) {
      return FlowPage(
        title: l.tripSummaryTitle,
        children: [Text(l.profileSignIn)],
      );
    }
    return FlowPage(
      title: l.tripSummaryTitle,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _summary,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(l.marketplaceLoadError),
                  TextButton(onPressed: _refresh, child: Text(l.retryLabel)),
                ],
              );
            }
            final data = snapshot.data!;
            final ride = AcceptedRide.fromJson(
              data['trip'] as Map<String, dynamic>,
            );
            final participants = (data['participants'] as List)
                .cast<Map<String, dynamic>>();
            final review = data['my_review'] as Map<String, dynamic>?;
            final costs = data['costs'] as Map<String, dynamic>?;
            final duration = (data['duration_seconds'] as num?)?.toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                FormSection(
                  title: l.tripSummaryTitle,
                  icon: Icons.flag_outlined,
                  children: [
                    FlowCopy(
                      ride.path.title,
                      rideDeparture(ride.path.departure),
                    ),
                    Text(l.rideStatusCompleted),
                    if (duration != null)
                      Text(l.tripDuration((duration / 60).ceil())),
                    if (ride.vehicleDetails != null)
                      Text(ride.vehicleDetails!.label),
                  ],
                ),
                FormSection(
                  title: l.tripParticipants,
                  icon: Icons.people_outline,
                  children: [
                    for (final participant in participants)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          participant['is_driver'] == true
                              ? Icons.drive_eta
                              : Icons.person_outline,
                        ),
                        title: Text(participant['name'] as String),
                        subtitle: Text(
                          participant['is_driver'] == true
                              ? l.tripDriver
                              : l.seatsValue(
                                  (participant['seats'] as num).toInt(),
                                ),
                        ),
                      ),
                  ],
                ),
                FormSection(
                  title: l.tripReviewTitle(ride.partner),
                  icon: Icons.star_outline,
                  children: [
                    if (review != null) ...[
                      Text(l.tripReviewSaved((review['score'] as num).toInt())),
                      if ((review['comment'] as String?)?.isNotEmpty == true)
                        Text(review['comment'] as String),
                    ] else ...[
                      Text(l.tripReviewHint),
                      Wrap(
                        children: [
                          for (var score = 1; score <= 5; score++)
                            IconButton(
                              tooltip: l.tripReviewStars(score),
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _score = score),
                              icon: Icon(
                                score <= _score
                                    ? Icons.star
                                    : Icons.star_border,
                              ),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                      TextField(
                        controller: _comment,
                        enabled: !_saving,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l.tripReviewComment,
                        ),
                      ),
                      PrimaryButton(
                        label: l.tripReviewSubmit,
                        isLoading: _saving,
                        onPressed: () => _submit(review: true),
                      ),
                    ],
                  ],
                ),
                FormSection(
                  title: l.tripCostsTitle,
                  icon: Icons.receipt_long_outlined,
                  children: [
                    Text(l.tripCostsRule),
                    if (costs != null) ...[
                      Text(
                        l.tripCostsTotal(
                          (costs['total_cost'] as num).toStringAsFixed(2),
                        ),
                      ),
                      for (final share
                          in (data['shares'] as List)
                              .cast<Map<String, dynamic>>())
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(share['name'] as String),
                          subtitle: share['mine'] == true
                              ? Text(l.tripYourShare)
                              : null,
                          trailing: Text(
                            '${(share['amount'] as num).toStringAsFixed(2)} MAD',
                          ),
                        ),
                    ] else if (ride.isDriver)
                      Form(
                        key: _costForm,
                        child: Column(
                          spacing: 12,
                          children: [
                            TextFormField(
                              controller: _total,
                              enabled: !_saving,
                              maxLength: 8,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l.tripCostsAmount,
                                suffixText: 'MAD',
                              ),
                              validator: (value) =>
                                  RegExp(r'^\d{1,5}([.,]\d{1,2})?$')
                                      .hasMatch(value?.trim() ?? '')
                                  ? null
                                  : l.tripCostsInvalid,
                            ),
                            PrimaryButton(
                              label: l.tripCostsPublish,
                              isLoading: _saving,
                              onPressed: () => _submit(review: false),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(l.tripCostsWaiting),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                TextButton.icon(
                  onPressed: _saving ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(l.refreshListings),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
