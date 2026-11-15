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
import '../../../shared/widgets/notification_bell.dart';
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

/// Grouping by proximity: a section title sits further from what precedes
/// it than from the content it introduces.
const double _sectionGapBefore = 26;
const double _sectionGapAfter = 8;

/// Entry motion: each block eases out over [_entryItemMs], the next one
/// starting [_entryStaggerMs] later.
const int _entryItemMs = 280;
const int _entryStaggerMs = 30;
const int _entryMaxBlocks = 8;

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
    duration: const Duration(
      milliseconds: _entryItemMs + _entryStaggerMs * (_entryMaxBlocks - 1),
    ),
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
    context.go('${AppRoutes.rides}?tab=offers');
  }

  void _openOffer() {
    context.go(AppRoutes.rideOffer);
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
      const SkeletonLoader(height: 92, radius: _actionCardRadius),
      const SkeletonLoader(height: 92, radius: _actionCardRadius),
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
      SectionTitle(title: l10n.homeActionsTitle),
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
        background: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: .5),
        foreground: Theme.of(context).colorScheme.primary,
        onTap: _openOffer,
      ),
      SectionTitle(title: l10n.homeUpcomingTripsTitle),
      if (overview.hasNoUpcomingTrips)
        EmptyState(
          title: l10n.homeNoUpcomingTripsTitle,
          message: l10n.homeNoUpcomingTripsMessage,
          icon: Icons.directions_car_outlined,
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
        const NotificationBell(),
      ],
    );
  }

  /// Interleaves [_blockGap] between [blocks] and applies the staggered entry
  /// animation, so callers can list the page content in reading order.
  List<Widget> _withGaps(List<Widget> blocks) {
    final children = <Widget>[];
    for (var index = 0; index < blocks.length; index++) {
      if (index > 0) {
        final gap = blocks[index] is SectionTitle
            ? _sectionGapBefore
            : blocks[index - 1] is SectionTitle
            ? _sectionGapAfter
            : _blockGap;
        children.add(SizedBox(height: gap));
      }
      children.add(
        _EntryTransition(
          animation: _entryAnimation(index),
          child: blocks[index],
        ),
      );
    }
    return children;
  }

  Animation<double> _entryAnimation(int index) {
    final total = _entryController.duration!.inMilliseconds;
    final startMs = _entryStaggerMs * index.clamp(0, _entryMaxBlocks - 1);
    return CurvedAnimation(
      parent: _entryController,
      // Ease-out: blocks arrive fast and settle softly.
      curve: Interval(
        startMs / total,
        (startMs + _entryItemMs) / total,
        curve: Curves.easeOutCubic,
      ),
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
    return _PressScale(
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(_actionCardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // A light tint of the card's own text colour: the default grey
          // highlight turned the dark card muddy while pressed.
          highlightColor: foreground.withValues(alpha: 0.08),
          splashColor: foreground.withValues(alpha: 0.12),
          child: Padding(
            // Compact enough to keep "Prochains trajets" visible on small phones.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    // Full strength: 7.5:1 on both cards (WCAG AAA), where the
                    // previous 90 % opacity gave 6:1 on the light card.
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shrinks its child to 97 % while a finger is down, like a physical button.
///
/// Follows the pointer directly (no tween while held), returns 20 % faster
/// than it presses in, never bounces, and is skipped with reduce motion.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? 0.97 : 1,
        duration: Duration(milliseconds: _pressed ? 100 : 80),
        curve: Curves.easeOut,
        child: widget.child,
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

    return _PressScale(
      child: AppCard(
        onTap: () => context.push(AppRoutes.acceptedRide(trip.id)),
        radius: _tripCardRadius,
        padding: const EdgeInsets.all(14),
        crossAxisAlignment: CrossAxisAlignment.center,
        trailing: AppBadge(
          label: trip.status == TripStatus.ongoing
              ? l10n.rideStatusOngoing
              : isConfirmed
              ? l10n.tripStatusConfirmed
              : l10n.tripStatusPending,
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
                // Fixed-width digits so "08:15" and "11:45" line up.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
