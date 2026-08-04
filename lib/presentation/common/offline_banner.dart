import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/providers/connectivity_provider.dart';

class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _visible = false;
  Timer? _timer;
  bool _hasTriggeredForCurrentOffline = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showFor3Seconds() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _visible = true;
      });
    }
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  void _hide() {
    _timer?.cancel();
    if (_visible && mounted) {
      setState(() {
        _visible = false;
      });
    }
  }

  void _checkState(bool isConnected) {
    if (!isConnected) {
      if (!_hasTriggeredForCurrentOffline) {
        _hasTriggeredForCurrentOffline = true;
        _showFor3Seconds();
      }
    } else {
      if (_hasTriggeredForCurrentOffline) {
        _hasTriggeredForCurrentOffline = false;
        _hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(isConnectedProvider, (previous, next) {
      final isConnected = next.valueOrNull ?? true;
      _checkState(isConnected);
    });

    final isConnectedAsync = ref.watch(isConnectedProvider);
    final isConnected = isConnectedAsync.valueOrNull ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkState(isConnected);
      }
    });

    return AnimatedCrossFade(
      firstChild: Container(
        width: double.infinity,
        color: AppColors.warningYellow,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 16, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'You\'re offline - Changes will sync when connected',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
      crossFadeState: _visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 300),
    );
  }
}
