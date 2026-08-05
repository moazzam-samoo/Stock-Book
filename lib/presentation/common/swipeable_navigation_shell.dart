import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget around [StatefulNavigationShell] that enables horizontal
/// swipe/slide navigation between main app tabs (Dashboard ↔ Transactions ↔ Settings)
/// and provides smooth sliding animations between tabs.
class SwipeableNavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const SwipeableNavigationShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  @override
  State<SwipeableNavigationShell> createState() => _SwipeableNavigationShellState();
}

class _SwipeableNavigationShellState extends State<SwipeableNavigationShell> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
  }

  @override
  void didUpdateWidget(covariant SwipeableNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _pageController.page?.round()) {
      _pageController.animateToPage(
        widget.navigationShell.currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index != widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: widget.children,
    );
  }
}
