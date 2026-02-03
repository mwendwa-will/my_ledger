import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/support_creator_screen.dart';

/// Helper class for managing and showing achievement milestones.
class MilestoneHelper {
  MilestoneHelper._();

  /// Checks if a transaction count milestone has been reached and shows a message.
  ///
  /// Milestones are checked at 10, 50, and 100 transactions.
  /// Each milestone is shown only once.
  static Future<void> checkTransactionMilestones(
    BuildContext context,
    int transactionCount,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final milestones = [10, 50, 100];

    for (final milestone in milestones) {
      if (transactionCount >= milestone) {
        final milestoneKey = 'milestone_${milestone}_shown';
        final alreadyShown = prefs.getBool(milestoneKey) ?? false;

        if (!alreadyShown) {
          await prefs.setBool(milestoneKey, true);
          if (context.mounted) {
            _showMilestoneSnackBar(context, milestone);
          }
          break; // Show only one milestone at a time.
        }
      }
    }
  }

  /// Shows a SnackBar celebrating the reached milestone.
  static void _showMilestoneSnackBar(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Congratulations! You have tracked $count transactions and are building great habits.',
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Support',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupportCreatorScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
