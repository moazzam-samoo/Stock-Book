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
import '../dashboard/screens/stock_detail_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../transactions/screens/transactions_screen.dart';
import '../splash/screens/splash_screen.dart';

import '../common/swipeable_navigation_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingSeen = ref.watch(onboardingControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') {
        return null;
      }
      final isLoggedIn = authState.valueOrNull != null;
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
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return PopScope(
            canPop: navigationShell.currentIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && navigationShell.currentIndex != 0) {
                navigationShell.goBranch(0);
              }
            },
            child: Scaffold(
              extendBody: true,
              backgroundColor: const Color(0xFF13151B),
              body: navigationShell,
              bottomNavigationBar: AppBottomNavBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
              ),
            ),
          );
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return SwipeableNavigationShell(
            navigationShell: navigationShell,
            children: children,
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
      GoRoute(
        path: '/stock/:ticker',
        builder: (context, state) {
          final ticker = state.pathParameters['ticker']!;
          return StockDetailScreen(ticker: ticker);
        },
      ),
    ],
  );
}
