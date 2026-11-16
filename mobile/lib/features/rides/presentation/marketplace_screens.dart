import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/marketplace_api.dart';
import '../domain/marketplace_models.dart';
import 'marketplace_map.dart';
import 'ride_summary_card.dart';
import '../application/active_rides_provider.dart';
import '../../notifications/data/ride_notices_provider.dart';
import 'trip_status.dart';

String rideDeparture(DateTime date) =>
    DateFormat.MMMEd('fr').add_Hm().format(date);

class MarketplaceBoard extends ConsumerStatefulWidget {
  const MarketplaceBoard({required this.initialTab, super.key});

  final int initialTab;

  @override
  ConsumerState<MarketplaceBoard> createState() => _MarketplaceBoardState();
}

class _MarketplaceBoardState extends ConsumerState<MarketplaceBoard> {
  late int _tab = widget.initialTab;
  late Future<List<Object>> _items = _load();

  Future<List<Object>> _load() {
    final api = ref.read(marketplaceApiProvider);
    final future = Future<List<Object>>.sync(
      () => _tab == 2 ? api.trips() : api.listings(ListingKind.values[_tab]),
    );
    // Attach an error listener immediately, before the next frame subscribes
    // through FutureBuilder. FutureBuilder still receives the original error.
    future.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return future;
  }

  void _reload() => setState(() {
    _items = _load();
  });

  void _select(int tab) {
    setState(() {
      _tab = tab;
      _items = _load();
    });
  }

  @override
  void didUpdateWidget(covariant MarketplaceBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) _select(widget.initialTab);
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final active =
        ref.watch(activeRidesProvider).asData?.value ?? <AcceptedRide>[];
    ref.listen(activeRidesProvider, (before, after) {
      String signature(List<AcceptedRide>? rides) =>
          rides?.map((r) => '${r.id}:${r.stage.name}').join(',') ?? '';
      if (after.hasValue &&
          signature(before?.asData?.value) != signature(after.asData?.value)) {
        _reload();
      }
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          children: [
            for (final entry in [
              l.rideRequests,
              l.rideOffers,
              l.myAcceptedRides,
            ].asMap().entries)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    selected: _tab == entry.key,
                    child: _tab == entry.key
                        ? FilledButton(
                            key: ValueKey('rides-tab-${entry.key}'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => _select(entry.key),
                            child: Text(
                              entry.value,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : OutlinedButton(
                            key: ValueKey('rides-tab-${entry.key}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => _select(entry.key),
                            child: Text(
                              entry.value,
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
        if (_tab < 2)
          PrimaryButton(
            label: _tab == 0 ? l.requestTitle : l.offerTitle,
            icon: Icons.add,
            onPressed: () =>
                _open(_tab == 0 ? AppRoutes.rideRequest : AppRoutes.rideOffer),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: Text(l.refreshListings),
          ),
        ),
        FutureBuilder<List<Object>>(
          key: ValueKey(_tab),
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(l.marketplaceLoadError),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(l.retryLabel),
                  ),
                ],
              );
            }
            final promoted = _tab == 2
                ? <AcceptedRide>[]
                : active
                      .where((r) => _tab == 1 || r.requestId != null)
                      .toList();
            final items = <Object>[
              ...promoted,
              ...(snapshot.data ?? []).where(
                (item) =>
                    item is! RideListing ||
                    !promoted.any(
                      (r) => _tab == 1
                          ? r.offerId == item.id
                          : r.requestId == item.id,
                    ),
              ),
            ];
            if (items.isEmpty) {
              return Text(switch (_tab) {
                0 => l.noRideRequests,
                1 => l.noRideOffers,
                _ => l.noAcceptedRides,
              });
            }

            return Column(
              spacing: 10,
              children: [
                for (final item in items)
                  switch (item) {
                    RideListing() => RideSummaryCard(
                      path: item.path,
                      author: item.author,
                      seats: item.seats,
                      onTap: () =>
                          _open(AppRoutes.listing(item.kind.name, item.id)),
                    ),
                    AcceptedRide() => RideSummaryCard(
                      path: item.path,
                      author:
                          '${item.partner} · ${tripStageLabel(l, item.stage)}',
                      activeStatus: item.stage.active
                          ? tripStageLabel(l, item.stage)
                          : null,
                      onTap: () => _open(AppRoutes.acceptedRide(item.id)),
                    ),
                    _ => const SizedBox.shrink(),
                  },
              ],
            );
          },
        ),
      ],
    );
  }
}

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({required this.kind, required this.id, super.key});

  final ListingKind kind;
  final String id;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  late Future<RideListing> _listing = _load();
  bool _accepting = false;

  Future<RideListing> _load() =>
      ref.read(marketplaceApiProvider).listing(widget.kind, widget.id);

  Future<void> _accept(RideListing listing) async {
    setState(() => _accepting = true);
    try {
      final booking = await ref.read(marketplaceApiProvider).accept(listing);
      ref.invalidate(activeRidesProvider);
      ref.invalidate(rideNoticesProvider);
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            Icons.check_circle,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l.tripBookingConfirmed),
          content: Text(listing.author),
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.near_me_outlined),
              label: Text(l.tripFollow),
            ),
          ],
        ),
      );
      if (mounted) context.pushReplacement(AppRoutes.acceptedRide(booking));
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.acceptRideError)));
      setState(() {
        _listing = _load();
      });
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<RideListing>(
      future: _listing,
      builder: (context, snapshot) {
        final listing = snapshot.data;
        return FlowPage(
          title: widget.kind == ListingKind.request
              ? l.rideRequestDetail
              : l.rideOfferDetail,
          children: [
            if (snapshot.hasError)
              Text(l.marketplaceLoadError)
            else if (listing == null)
              const LinearProgressIndicator()
            else ...[
              AppCard(
                leading: Avatar(name: listing.author),
                child: FlowCopy(listing.author, l.seatsValue(listing.seats)),
              ),
              FlowCopy(
                listing.path.title,
                rideDeparture(listing.path.departure),
              ),
              if (listing.notes case final notes? when notes.isNotEmpty)
                Text(notes),
              Text(l.approximatePickup),
              MarketplaceMap(path: listing.path, previewOnOpen: true),
              if (listing.canAccept)
                PrimaryButton(
                  label: l.acceptRide,
                  isLoading: _accepting,
                  onPressed: () => _accept(listing),
                )
              else
                Text(listing.own ? l.ownRideListing : l.rideUnavailable),
            ],
          ],
        );
      },
    );
  }
}
