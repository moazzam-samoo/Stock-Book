import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_line_chart.dart';
import '../widgets/onboarding_donut_chart.dart';
import '../widgets/onboarding_live_price.dart';
import '../widgets/onboarding_alert_bell.dart';
import '../widgets/onboarding_position_average.dart';
import '../widgets/page_indicator_dots.dart';
import '../../../core/theme/app_colors.dart';

const int _lastPageIndex = 4;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Onboarding deliberately always uses a light background with the dark
    // theme's vivid accent colors (green line, chart segments) kept as-is —
    // its own fixed look, not tied to the user's light/dark/system setting
    // like every other screen.
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  ref.read(onboardingControllerProvider.notifier).completeOnboarding();
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 16),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Track Every Trade',
                    description: 'Log your stock buys and sells with precision. Know exactly what you hold and what you\'ve realized.',
                    animationWidget: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: OnboardingLineChart(),
                    ),
                  ),
                  _buildPage(
                    title: 'Analyze Your Portfolio',
                    description: 'Visualize your asset allocation and overall performance. Make data-driven investment decisions.',
                    animationWidget: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: OnboardingDonutChart(),
                    ),
                  ),
                  _buildPage(
                    title: 'Live Market Prices',
                    description: 'Real-time PSX prices, updated automatically — plus a clear open/closed market indicator so you always know what\'s happening right now.',
                    animationWidget: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: OnboardingLivePrice(),
                    ),
                  ),
                  _buildPage(
                    title: 'Never Miss Your Target',
                    description: 'Set a target price and get notified the instant it hits — even when the app is closed.',
                    animationWidget: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: OnboardingAlertBell(),
                    ),
                  ),
                  _buildPage(
                    title: 'Buy Anytime, One Clear Average',
                    description: 'Buy the same stock multiple times and we automatically calculate your average cost — with realized and unrealized profit always split out correctly.',
                    animationWidget: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: OnboardingPositionAverage(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PageIndicatorDots(pageCount: 5, currentPage: _currentPage),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_currentPage == _lastPageIndex) {
                        ref.read(onboardingControllerProvider.notifier).completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Text(_currentPage == _lastPageIndex ? 'Get Started' : 'Next', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required Widget animationWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: animationWidget),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
