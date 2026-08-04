import 'package:flutter/material.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/common/buttons.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.offBlack),
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.neutral500.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: AppColors.textPrimaryDark),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.body.copyWith(color: AppColors.neutral500),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: buttonLabel!,
                onPressed: onButtonPressed!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
