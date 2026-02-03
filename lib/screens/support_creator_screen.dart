import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/support_links.dart';
import '../utils/url_launcher_helper.dart';

/// Screen that provides users with options to support app development.
///
/// This screen is completely optional and never blocks app functionality.
/// All donation links open in external browser to maintain privacy.
class SupportCreatorScreen extends StatelessWidget {
  const SupportCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support MyLedger'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThankYouCard(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Ways to Support'),
            const SizedBox(height: 16),
            _buildSupportOption(
              context,
              icon: Icons.coffee,
              title: 'Buy Me a Coffee',
              description: 'One-time support via Ko-fi',
              amount: '3 - 10 USD',
              color: const Color(0xFFFF5E5B),
              url: SupportLinks.kofiUrl,
            ),
            _buildSupportOption(
              context,
              icon: Icons.favorite,
              title: 'GitHub Sponsors',
              description: 'Monthly support on GitHub',
              amount: '5 USD per month',
              color: const Color(0xFFEA4AAA),
              url: SupportLinks.githubSponsors,
            ),
            _buildSupportOption(
              context,
              icon: Icons.payment,
              title: 'PayPal',
              description: 'Direct one-time donation',
              amount: 'Any amount',
              color: const Color(0xFF0070BA),
              url: SupportLinks.paypalUrl,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Other Ways to Help'),
            const SizedBox(height: 16),
            _buildFreeOption(
              context,
              icon: Icons.star,
              title: 'Rate on App Store',
              description: 'Leave a 5-star review',
              onTap: () => _handleRateApp(context),
            ),
            _buildFreeOption(
              context,
              icon: Icons.share,
              title: 'Share with Friends',
              description: 'Recommend MyLedger to others',
              onTap: () => _handleShareApp(context),
            ),
            _buildFreeOption(
              context,
              icon: Icons.bug_report,
              title: 'Report Bugs',
              description: 'Help improve the app',
              onTap: () => UrlLauncherHelper.launchURL(
                context,
                SupportLinks.githubIssues,
              ),
            ),
            _buildFreeOption(
              context,
              icon: Icons.code,
              title: 'Contribute Code',
              description: 'Open source on GitHub',
              onTap: () => UrlLauncherHelper.launchURL(
                context,
                SupportLinks.githubRepo,
              ),
            ),
            const SizedBox(height: 32),
            _buildPromiseCard(context),
            const SizedBox(height: 16),
            _buildTransparencyCard(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Section header with consistent styling.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  /// Thank you card at the top.
  Widget _buildThankYouCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.favorite,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Thank You for Using MyLedger',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'MyLedger is completely free, open-source, and respects your privacy. '
              'Your data never leaves your device. If you find this app helpful, '
              'consider supporting its development.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Support option card with donation link.
  Widget _buildSupportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String amount,
    required Color color,
    required String url,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          UrlLauncherHelper.launchURL(context, url);
        },
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          button: true,
          label: '$title. $description. Suggested amount: $amount. Opens external link.',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha((0.6 * 255).round()),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha((0.4 * 255).round()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Free support option (no payment required).
  Widget _buildFreeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }

  /// Promise card explaining app principles.
  Widget _buildPromiseCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Our Promise',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCheckItem(context, 'Always free and open source'),
            _buildCheckItem(context, 'No ads ever'),
            _buildCheckItem(context, 'No tracking or data collection'),
            _buildCheckItem(context, 'Works completely offline'),
            _buildCheckItem(context, 'Your data stays on your device'),
          ],
        ),
      ),
    );
  }

  /// Transparency card showing where support goes.
  Widget _buildTransparencyCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Where Your Support Goes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBulletItem(context, 'Development time for new features'),
            _buildBulletItem(context, 'App Store fees'),
            _buildBulletItem(context, 'Testing devices'),
            _buildBulletItem(context, 'Server costs for website'),
            _buildBulletItem(context, 'Coffee and motivation'),
          ],
        ),
      ),
    );
  }

  /// Check mark list item.
  Widget _buildCheckItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bullet point list item.
  Widget _buildBulletItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles rating the app - detects platform and opens appropriate store.
  void _handleRateApp(BuildContext context) {
    String storeUrl;

    try {
      if (Platform.isIOS) {
        storeUrl = SupportLinks.appStoreUrl;
      } else if (Platform.isAndroid) {
        storeUrl = SupportLinks.playStoreUrl;
      } else {
        _showStoreSelectionDialog(context);
        return;
      }

      UrlLauncherHelper.launchURL(context, storeUrl);
    } catch (e) {
      _showStoreSelectionDialog(context);
    }
  }

  /// Shows dialog to select app store (for platforms where detection fails).
  void _showStoreSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate MyLedger'),
        content: const Text('Choose your platform:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              UrlLauncherHelper.launchURL(
                context,
                SupportLinks.appStoreUrl,
              );
            },
            child: const Text('App Store'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              UrlLauncherHelper.launchURL(
                context,
                SupportLinks.playStoreUrl,
              );
            },
            child: const Text('Play Store'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Handles sharing the app.
  void _handleShareApp(BuildContext context) {
    SharePlus.instance.share(ShareParams(
      text: 'Check out MyLedger - a free, privacy-focused budgeting app that works completely offline! '
      'Your data never leaves your device. Download it now: ${SupportLinks.website}',
      subject: 'MyLedger - Privacy-First Budgeting App',
    ),);
  }
}
