import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../application/home_controller.dart';
import '../application/home_state.dart';
import '../domain/home_overview.dart';
import '../domain/upcoming_trip.dart';

/// Radius of the two large action cards, taken from the mockup (22 px).
const double _actionCardRadius = 22;

/// Radius of the trip cards, taken from the mockup (18 px).
const double _tripCardRadius = 18;

/// Gap between the blocks of the page, taken from the mockup (14 px).
const double _blockGap = 14;

/// Accueil tab matching the second mockup of `EMSIDrive_maquettes_mobile.html`.
///
/// Shows a greeting, the two ride actions and the next trips of the student.
/// Content comes from [HomeController]; the list supports pull-to-refresh and
/// every block fades and slides in when the overview is first loaded.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    value: 1,
  );

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(homeControllerProvider.notifier).refresh();
  }

  void _retry() {
    ref.read(homeControllerProvider.notifier).reload();
  }

  void _openSearch() {
    context.go(AppRoutes.rides);
  }

  void _openOffer() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.placeholderMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeControllerProvider);

    ref.listen<HomeState>(homeControllerProvider, (previous, next) {
      if (next is HomeLoaded && previous is! HomeLoaded) {
        _entryController.forward(from: 0);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            children: switch (state) {
              HomeLoading() => _buildSkeleton(),
              HomeError(:final failure) => _buildError(l10n, failure),
              HomeLoaded(:final overview) => _buildContent(l10n, overview),
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSkeleton() {
    return _withGaps(<Widget>[
      const Row(
        children: <Widget>[
          SkeletonLoader(width: 56, height: 34, radius: AppRadius.sm),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonLoader.line(width: 64),
                SizedBox(height: AppSpacing.sm),
                SkeletonLoader(width: 108, height: 16, radius: AppRadius.xs),
              ],
            ),
          ),
          SkeletonLoader(width: 46, height: 46, radius: AppRadius.pill),
        ],
      ),
      const SkeletonLoader(height: 104, radius: _actionCardRadius),
      const SkeletonLoader(height: 104, radius: _actionCardRadius),
      const SkeletonLoader.line(width: 148, radius: AppRadius.xs),
      const SkeletonLoader(height: 74, radius: _tripCardRadius),
      const SkeletonLoader(height: 74, radius: _tripCardRadius),
    ]);
  }

  List<Widget> _buildError(AppLocalizations l10n, AppFailure failure) {
    return <Widget>[
      const SizedBox(height: AppSpacing.xxxl),
      ErrorState(
        title: l10n.homeErrorTitle,
        message: _failureMessage(l10n, failure),
        retryLabel: l10n.retryLabel,
        onRetry: _retry,
      ),
    ];
  }

  List<Widget> _buildContent(AppLocalizations l10n, HomeOverview overview) {
    final blocks = <Widget>[
      _buildGreeting(l10n, overview.displayName),
      _HomeActionCard(
        title: l10n.homeSearchRideTitle,
        subtitle: l10n.homeSearchRideSubtitle,
        background: Theme.of(context).colorScheme.primary,
        foreground: Theme.of(context).colorScheme.onPrimary,
        onTap: _openSearch,
      ),
      _HomeActionCard(
        title: l10n.homeOfferRideTitle,
        subtitle: l10n.homeOfferRideSubtitle,
        background: Theme.of(context).colorScheme.secondary,
        foreground: Theme.of(context).colorScheme.onSecondary,
        onTap: _openOffer,
      ),
      SectionTitle(title: l10n.homeUpcomingTripsTitle),
      if (overview.hasNoUpcomingTrips)
        EmptyState(
          title: l10n.homeNoUpcomingTripsTitle,
          message: l10n.homeNoUpcomingTripsMessage,
          icon: Icons.route_outlined,
        )
      else
        ...overview.upcomingTrips.map(
          (trip) => _UpcomingTripCard(trip: trip, l10n: l10n),
        ),
    ];

    return _withGaps(blocks);
  }

  Widget _buildGreeting(AppLocalizations l10n, String displayName) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Image.asset(
          AppAssets.logo,
          height: 34,
          fit: BoxFit.contain,
          semanticLabel: l10n.appName,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.homeGreeting,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Avatar(name: displayName, size: 46),
      ],
    );
  }

  /// Interleaves [_blockGap] between [blocks] and applies the staggered entry
  /// animation, so callers can list the page content in reading order.
  List<Widget> _withGaps(List<Widget> blocks) {
    final children = <Widget>[];
    for (var index = 0; index < blocks.length; index++) {
      if (index > 0) {
        children.add(const SizedBox(height: _blockGap));
      }
      children.add(
        _EntryTransition(animation: _entryAnimation(index), child: blocks[index]),
      );
    }
    return children;
  }

  Animation<double> _entryAnimation(int index) {
    final start = (index * 0.08).clamp(0.0, 0.55);
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
  }

  String _failureMessage(AppLocalizations l10n, AppFailure failure) {
    return switch (failure) {
      NetworkFailure() => l10n.networkErrorMessage,
      TimeoutFailure() => l10n.timeoutErrorMessage,
      _ => l10n.genericErrorMessage,
    };
  }
}

/// Wraps a page block in a fade plus a short upward slide.
class _EntryTransition extends StatelessWidget {
  const _EntryTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Large call-to-action card of the Accueil page.
class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(_actionCardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.42,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: foreground.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trip row of the "Prochains trajets" section.
class _UpcomingTripCard extends StatelessWidget {
  const _UpcomingTripCard({required this.trip, required this.l10n});

  final UpcomingTrip trip;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driver = trip.driverName;
    final subtitle = driver == null
        ? l10n.homeTripPending(trip.timeLabel)
        : l10n.homeTripWithDriver(trip.timeLabel, driver);
    final isConfirmed = trip.status == TripStatus.confirmed;

    return AppCard(
      radius: _tripCardRadius,
      padding: const EdgeInsets.all(14),
      crossAxisAlignment: CrossAxisAlignment.center,
      trailing: AppBadge(
        label: isConfirmed ? l10n.tripStatusConfirmed : l10n.tripStatusPending,
        tone: isConfirmed ? AppBadgeTone.accent : AppBadgeTone.warning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.homeTripRoute(trip.origin, trip.destination),
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
