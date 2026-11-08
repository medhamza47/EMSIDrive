import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/schedule/presentation/planning_screen.dart';
import '../../features/matching/presentation/suggestion_screens.dart';
import '../../features/rides/data/demo_drivers.dart';
import '../../features/rides/domain/marketplace_models.dart';
import '../../features/rides/presentation/accepted_ride_screen.dart';
import '../../features/rides/presentation/marketplace_screens.dart';
import '../../features/rides/presentation/driver_screens.dart';
import '../../features/rides/presentation/ride_completion_screens.dart';
import '../../features/rides/presentation/ride_request_screen.dart';
import '../../features/rides/presentation/ride_tracking_screen.dart';
import '../../features/rides/presentation/rides_screen.dart';
import '../../features/schedule/presentation/schedule_screens.dart';
import '../../features/schedule/domain/schedule_models.dart';
import '../../shared/widgets/app_bottom_nav_bar.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Router instance exposed to the app.
///
/// Kept alive so the navigation state survives rebuilds of the widget tree.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => createAppRouter();

/// Builds the [GoRouter] instance driving the app.
///
/// A [StatefulShellRoute.indexedStack] gives each of the four tabs its own
/// navigation stack while keeping the bottom bar permanently visible. The two
/// authentication routes live outside the shell so they render full screen.
GoRouter createAppRouter({String initialLocation = AppRoutes.initial}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/trip/:id',
        builder: (_, state) =>
            AcceptedRideScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/rides/schedule',
        redirect: (_, _) => AppRoutes.scheduleImport,
      ),
      GoRoute(
        path: '/rides/slots',
        redirect: (_, _) => AppRoutes.scheduleSlots,
      ),
      GoRoute(
        path: '/rides/suggestions',
        redirect: (_, _) => AppRoutes.suggestions,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.rides,
                builder: (_, state) => RidesScreen(
                  key: ValueKey(state.uri.queryParameters['tab']),
                  initialTab: state.uri.queryParameters['tab'] == 'requests'
                      ? 0
                      : state.uri.queryParameters['tab'] == 'mine'
                      ? 2
                      : 1,
                ),
                routes: [
                  GoRoute(
                    path: 'listings/:kind/:id',
                    builder: (_, state) => ListingDetailScreen(
                      kind: state.pathParameters['kind'] == 'offer'
                          ? ListingKind.offer
                          : ListingKind.request,
                      id: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'request',
                    builder: (_, _) => const RideRequestScreen(),
                  ),
                  GoRoute(
                    path: 'offer',
                    builder: (_, _) => const RideRequestScreen(isOffer: true),
                  ),
                  GoRoute(
                    path: 'nearby',
                    builder: (_, _) => const NearbyDriversScreen(),
                  ),
                  GoRoute(
                    path: 'driver/:id',
                    builder: (_, state) => DriverDetailScreen(
                      driver: DemoDriver.find(state.pathParameters['id']),
                    ),
                  ),
                  GoRoute(
                    path: 'tracking',
                    builder: (_, _) =>
                        RideTrackingScreen(driver: DemoDriver.all.first),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => RideTrackingScreen(
                          driver: DemoDriver.find(state.pathParameters['id']),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'fuel',
                    builder: (_, _) => const FuelSplitScreen(),
                  ),
                  GoRoute(
                    path: 'review',
                    builder: (_, _) => const RideReviewScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.planning,
                builder: (_, _) => const PlanningScreen(),
                routes: [
                  GoRoute(
                    path: 'import',
                    builder: (_, _) => const ScheduleImportScreen(),
                  ),
                  GoRoute(
                    path: 'review',
                    builder: (_, state) => ScheduleSlotsScreen(
                      initial: state.extra is Timetable
                          ? state.extra as Timetable
                          : null,
                    ),
                  ),
                  GoRoute(
                    path: 'suggestions',
                    builder: (_, _) => const SuggestionsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => ListingDetailScreen(
                          kind: ListingKind.offer,
                          id: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: "edit",
                    builder: (_, _) => const ProfileEditScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Shell hosting the four tab branches and the bottom navigation bar.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  /// Branch container maintained by the router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppTab.values[navigationShell.currentIndex],

        onTabSelected: (tab) => navigationShell.goBranch(
          tab.index,
          initialLocation: tab.index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
