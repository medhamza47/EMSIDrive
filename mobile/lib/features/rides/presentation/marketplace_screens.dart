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
    return _tab == 2 ? api.trips() : api.listings(ListingKind.values[_tab]);
  }

  void _reload() => setState(() => _items = _load());

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, label: Text(l.rideRequests)),
            ButtonSegment(value: 1, label: Text(l.rideOffers)),
            ButtonSegment(value: 2, label: Text(l.myAcceptedRides)),
          ],
          selected: {_tab},
          onSelectionChanged: (selection) {
            _tab = selection.single;
            _reload();
          },
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
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) return Text(l.marketplaceLoadError);
            final items = snapshot.data ?? [];
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
                    RideListing() => AppCard(
                      leading: Avatar(name: item.author),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _open(AppRoutes.listing(item.kind.name, item.id)),
                      child: FlowCopy(
                        item.path.title,
                        '${item.author} · ${rideDeparture(item.path.departure)} · ${l.seatsValue(item.seats)}',
                      ),
                    ),
                    AcceptedRide() => AppCard(
                      leading: Avatar(name: item.partner),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(AppRoutes.acceptedRide(item.id)),
                      child: FlowCopy(
                        item.path.title,
                        '${item.partner} · ${rideDeparture(item.path.departure)}',
                      ),
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
      if (mounted) context.pushReplacement(AppRoutes.acceptedRide(booking));
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.acceptRideError)));
      setState(() => _listing = _load());
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
