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
import 'ride_lifecycle.dart';
import 'ride_request_screen.dart';
import '../../home/application/home_controller.dart';

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
  bool _mine = false;
  bool _history = false;

  Future<List<Object>> _load() {
    final api = ref.read(marketplaceApiProvider);
    return _tab == 2
        ? api.trips(history: _history)
        : api.listings(ListingKind.values[_tab], mine: _mine);
  }

  void _reload() {
    final items = _load();
    setState(() {
      _items = items;
    });
  }

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
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: Text(l.rideMyListings),
              selected: _mine,
              onSelected: (value) {
                _mine = value;
                _reload();
              },
            ),
          )
        else
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.rideActiveTrips)),
              ButtonSegment(value: true, label: Text(l.rideHistory)),
            ],
            selected: {_history},
            onSelectionChanged: (value) {
              _history = value.single;
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
                _ => _history ? l.rideNoHistory : l.noAcceptedRides,
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
                      status: rideStatusLabel(l, item.status),
                      onTap: () =>
                          _open(AppRoutes.listing(item.kind.name, item.id)),
                    ),
                    AcceptedRide() => RideSummaryCard(
                      path: item.path,
                      author: item.partner,
                      status: rideStatusLabel(l, item.status),
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

  Future<void> _editListing(RideListing listing) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RideRequestScreen(
          isOffer: listing.kind == ListingKind.offer,
          editing: listing,
        ),
      ),
    );
    if (!mounted) return;
    final listingFuture = _load();
    setState(() {
      _listing = listingFuture;
    });
  }

  Future<void> _cancelListing(RideListing listing) async {
    final l = AppLocalizations.of(context);
    if (!await confirmRideAction(context, l.rideCancelListingHint) ||
        !mounted) {
      return;
    }
    setState(() => _accepting = true);
    try {
      await ref.read(marketplaceApiProvider).cancelListing(listing);
      ref.invalidate(homeControllerProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.rideActionFailed)));
      }
    } finally {
      if (mounted) {
        final listingFuture = _load();
        setState(() {
          _accepting = false;
          _listing = listingFuture;
        });
      }
    }
  }

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
      final refreshedListing = _load();
      setState(() {
        _listing = refreshedListing;
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
              Text(rideStatusLabel(l, listing.status)),
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
              if (!listing.own) Text(l.approximatePickup),
              MarketplaceMap(path: listing.path, previewOnOpen: true),
              if (listing.canAccept)
                PrimaryButton(
                  label: l.acceptRide,
                  isLoading: _accepting,
                  onPressed: () => _accept(listing),
                )
              else
                Text(listing.own ? l.ownRideListing : l.rideUnavailable),
              if (listing.own && listing.canEdit)
                OutlinedButton.icon(
                  onPressed: _accepting ? null : () => _editListing(listing),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l.rideEditListing),
                ),
              if (listing.own && !listing.canEdit && listing.canCancel)
                Text(l.rideEditLocked),
              if (listing.own && listing.canCancel)
                OutlinedButton.icon(
                  onPressed: _accepting ? null : () => _cancelListing(listing),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l.rideCancelListing),
                ),
            ],
          ],
        );
      },
    );
  }
}
