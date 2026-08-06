import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/onboarding/providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_navigateToNext());
  }

  Future<void> _navigateToNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;
    final onboardingSeen = ref.read(onboardingControllerProvider);

    if (!onboardingSeen && !isLoggedIn) {
      context.go('/onboarding');
    } else if (!isLoggedIn) {
      context.go('/sign-in');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // High-resolution original logo card
            Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icon/Stockk.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
                .animate()
                .scale(duration: 800.ms, curve: Curves.easeOutBack)
                .fade(duration: 600.ms),

            const SizedBox(height: 28),

            // Styled App Title "Stock Book"
            Text(
                  'Stock Book',
                  style: GoogleFonts.outfit(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: 600.ms,
                  delay: 200.ms,
                  curve: Curves.easeOutCubic,
                )
                .fade(duration: 600.ms, delay: 200.ms),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Track. Analyze. Profit.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral500,
                letterSpacing: 2,
              ),
            ).animate().fade(duration: 600.ms, delay: 400.ms),

            const Spacer(),

            // Bottom subtle branding
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    size: 16,
                    color: AppColors.moneyGreen.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Powered by Coding District',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral500.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 600.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
