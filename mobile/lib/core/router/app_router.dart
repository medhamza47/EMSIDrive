import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/matching/presentation/suggestion_screens.dart';
import '../../features/rides/data/demo_drivers.dart';
import '../../features/rides/presentation/driver_screens.dart';
import '../../features/rides/presentation/ride_completion_screens.dart';
import '../../features/rides/presentation/ride_request_screen.dart';
import '../../features/rides/presentation/ride_tracking_screen.dart';
import '../../features/rides/presentation/rides_screen.dart';
import '../../features/schedule/presentation/schedule_screens.dart';
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
                builder: (context, state) => const RidesScreen(),
                routes: [
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
                  GoRoute(
                    path: 'schedule',
                    builder: (_, _) => const ScheduleImportScreen(),
                  ),
                  GoRoute(
                    path: 'slots',
                    builder: (_, _) => const ScheduleSlotsScreen(),
                  ),
                  GoRoute(
                    path: 'suggestions',
                    builder: (_, _) => const SuggestionsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => SuggestionDetailScreen(
                          driver: DemoDriver.find(state.pathParameters['id']),
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
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Shell hosting the four tab branches and the bottom navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  /// Branch container maintained by the router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
