import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';

/// Pushed above the shell like [StockDetailScreen] — raw [Scaffold], not
/// [AppScaffold], since this isn't one of the three shell tabs.
class CompanyOwnersScreen extends StatelessWidget {
  const CompanyOwnersScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Could not launch URL
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(title: 'Company & Owners', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'COMPANY'),
                  const SizedBox(height: 12),
                  _buildCompanyCard(isDark, primaryTextColor),
                  const SizedBox(height: 28),

                  _sectionTitle(context, 'WHY WE BUILT STOCK BOOK'),
                  const SizedBox(height: 12),
                  _buildMotivationCard(isDark, primaryTextColor, secondaryTextColor),
                  const SizedBox(height: 28),

                  _sectionTitle(context, 'OWNERS'),
                  const SizedBox(height: 12),
                  _buildOwnerCard(
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    photoAsset: 'assets/icon/dev-mozzam.jpg',
                    initials: 'MS',
                    name: 'Moazzam Samoo',
                    role: 'Owner & Lead Developer',
                    portfolioUrl: 'https://moazzam-samoo.web.app/',
                    linkedInUrl:
                        'https://www.linkedin.com/in/moazzam-samoo?utm_source=share_via&utm_content=profile&utm_medium=member_android',
                  ),
                  const SizedBox(height: 12),
                  _buildOwnerCard(
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    photoAsset: 'assets/icon/dev-kheeraj.jpg',
                    initials: 'KD',
                    name: 'Kheeraj Das',
                    role: 'Owner & Developer',
                    portfolioUrl: null,
                    linkedInUrl: 'https://www.linkedin.com/in/kheeraj-das-588584345/',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
      boxShadow: isDark
          ? null
          : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
    );
  }

  Widget _buildCompanyCard(bool isDark, Color primaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/icon/android-chrome-192x192.png',
                  width: 52,
                  height: 52,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.brandIndigo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_rounded, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coding District',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor),
                    ),
                    const Text(
                      'Software Engineering & AI Solutions',
                      style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              _buildIconLinkButton(
                icon: Icons.language_rounded,
                onTap: () => _launchURL('https://codingdistrict.com'),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildIconLinkButton(
                icon: Icons.business_center_rounded,
                onTap: () => _launchURL('https://www.linkedin.com/company/codingdistrict/'),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Coding District is a software studio building focused, well-crafted tools '
            'rather than bloated ones. Stock Book is one of those tools.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFFB3B3B3) : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: _cardDecoration(isDark),
      child: Text(
        'Tracking a Pakistan Stock Exchange portfolio properly meant either a messy spreadsheet '
        'or an app built for a completely different market. We wanted something that actually '
        'understood PSX — average cost across multiple buys, realized vs. unrealized profit, '
        'live prices, and a target-price alert that doesn\'t need you to keep the app open. '
        'Stock Book is the tool we wished existed, built for ourselves first and shared with '
        'every other PSX investor who\'s hit the same wall.',
        style: TextStyle(fontSize: 13, height: 1.6, color: secondaryTextColor),
      ),
    );
  }

  Widget _buildOwnerCard({
    required bool isDark,
    required Color primaryTextColor,
    required String photoAsset,
    required String initials,
    required String name,
    required String role,
    required String? portfolioUrl,
    required String linkedInUrl,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              photoAsset,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.brandIndigo,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (portfolioUrl == null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.neutral500.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Portfolio — Coming Soon',
                      style: TextStyle(fontSize: 9, color: AppColors.neutral500, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (portfolioUrl != null) ...[
            _buildIconLinkButton(
              icon: Icons.person_pin_rounded,
              onTap: () => _launchURL(portfolioUrl),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
          ],
          _buildIconLinkButton(
            icon: Icons.link_rounded,
            onTap: () => _launchURL(linkedInUrl),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildIconLinkButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.brandIndigo.withOpacity(isDark ? 0.18 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.brandIndigo),
      ),
    );
  }
}
