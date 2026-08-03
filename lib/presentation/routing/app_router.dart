import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../auth/providers/auth_providers.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../common/app_bottom_nav_bar.dart';
import '../common/app_scaffold.dart';
import '../auth/screens/sign_in_screen.dart';
import '../onboarding/screens/onboarding_screen.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../transactions/screens/transactions_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);
  final isMockLoggedIn = ref.watch(mockAuthNotifierProvider);
  final onboardingSeen = ref.watch(onboardingControllerProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = (authState.valueOrNull != null) || isMockLoggedIn;
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToSignIn = state.matchedLocation == '/sign-in';

      // 1. Unauthenticated users who haven't seen onboarding go to onboarding
      if (!onboardingSeen && !isLoggedIn && !isGoingToOnboarding) {
        return '/onboarding';
      }

      // 2. Unauthenticated users who HAVE seen onboarding go to sign-in
      if (onboardingSeen && !isLoggedIn && !isGoingToSignIn) {
        return '/sign-in';
      }

      // 3. Authenticated users shouldn't be on auth/onboarding screens
      if (isLoggedIn && (isGoingToSignIn || isGoingToOnboarding)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(
            body: navigationShell,
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add-stock',
        builder: (context, state) => const Center(child: Text('Add Stock Placeholder')),
      ),
    ],
  );
}
