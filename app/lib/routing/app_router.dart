import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/supabase_config.dart';

import '../features/advisory/presentation/advisory_screen.dart';
import '../features/ai_assistant/presentation/ai_conversation_screen.dart';
import '../features/ai_assistant/presentation/ask_ai_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/crop_scanner/presentation/scanner_screen.dart';
import '../features/crops/presentation/add_first_crop_screen.dart';
import '../features/crops/presentation/crop_details_screen.dart';
import '../features/crops/presentation/crops_overview_screen.dart';
import '../features/dashboard/presentation/home_dashboard_screen.dart';
import '../features/farmer/presentation/farm_profile_screen.dart';
import '../features/farmer/presentation/profile_screen.dart';
import '../features/fields/presentation/fields_screen.dart';
import '../features/location/presentation/location_setup_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/profile/presentation/privacy_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/tasks/presentation/activity_timeline_screen.dart';
import '../features/tasks/presentation/task_details_screen.dart';
import '../data/models/task.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/weather/presentation/forecast_screen.dart';
import '../features/weather/presentation/weather_overview_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_routes.dart';

/// Bottom tabs required by the prototype: Home / Crops / AI / Tasks / Profile.
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grass_outlined),
            selectedIcon: const Icon(Icons.grass),
            label: l.navCrops,
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: l.navAi,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_outlined),
            selectedIcon: const Icon(Icons.task),
            label: l.navTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: l.navProfile,
          ),
        ],
      ),
    );
  }
}

/// Auth-guarded go_router (Phase 2). With a live backend configured,
/// onboarding + shell routes require a session (redirect to sign-in).
/// In UI-shell mode (unconfigured) every route stays reachable.
GoRouter buildRouter({
  Listenable? refreshListenable,
  bool Function()? isSignedIn,
}) {
  bool signedIn() => isSignedIn?.call() ?? false;

  String? guard(BuildContext context, GoRouterState state) {
    if (!SupabaseConfig.isConfigured) return null;
    final loc = state.matchedLocation;
    const open = [
      AppRoutes.splash,
      AppRoutes.welcome,
      AppRoutes.signIn,
      AppRoutes.privacy,
    ];
    if (!signedIn()) {
      if (open.any((p) => loc == p || loc.startsWith('$p/'))) return null;
      return AppRoutes.signIn;
    }
    if (loc == AppRoutes.signIn) return AppRoutes.home;
    return null;
  }

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: guard,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, _) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.locationSetup,
        builder: (_, _) => const LocationSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmProfile,
        builder: (_, _) => const FarmProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.addCrop,
        builder: (_, _) => const AddFirstCropScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'weather',
                    builder: (_, _) => const WeatherOverviewScreen(),
                    routes: [
                      GoRoute(
                        path: 'forecast',
                        builder: (_, _) => const ForecastScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'advisory',
                    builder: (_, _) => const AdvisoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.crops,
                builder: (_, _) => const CropsOverviewScreen(),
                routes: [
                  GoRoute(
                    path: 'details',
                    builder: (_, _) => const CropDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'scanner',
                    builder: (_, _) => const ScannerScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.askAi,
                builder: (_, _) => const AskAiScreen(),
                routes: [
                  GoRoute(
                    path: 'conversation',
                    builder: (_, _) => const AiConversationScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                builder: (_, _) => const TasksScreen(),
                routes: [
                  GoRoute(
                    path: 'details',
                    builder: (_, state) => TaskDetailsScreen(
                      task: state.extra is FarmTask
                          ? state.extra as FarmTask
                          : null,
                    ),
                  ),
                  GoRoute(
                    path: 'timeline',
                    builder: (_, _) => const ActivityTimelineScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'fields',
                    builder: (_, _) => const FieldsScreen(),
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
