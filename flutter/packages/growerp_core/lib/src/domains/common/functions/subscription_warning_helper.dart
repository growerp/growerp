/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for managing subscription expiration warning dialogs.
///
/// Shows a warning dialog when subscription is about to expire (last 3 days).
/// Limits display to once per day per tenant.
class SubscriptionWarningHelper {
  /// SharedPreferences key prefix for tracking daily warning state
  static const String _keyPrefix = 'subscription_warning_';

  /// Check if subscription warning should be shown.
  ///
  /// Returns true if:
  /// - Subscription has 1-3 days remaining
  /// - Warning hasn't been shown today for this tenant
  static Future<bool> shouldShowWarning(Authenticate? authenticate) async {
    final daysRemaining = authenticate?.subscriptionDaysRemaining;
    if (daysRemaining == null || daysRemaining > 3 || daysRemaining <= 0) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        '$_keyPrefix${authenticate!.ownerPartyId}_${today.year}_${today.month}_${today.day}';
    return !(prefs.getBool(key) ?? false);
  }

  /// Mark the warning as shown for today.
  static Future<void> markAsShownToday(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        '$_keyPrefix${ownerPartyId}_${today.year}_${today.month}_${today.day}';
    await prefs.setBool(key, true);
  }

  /// Show the subscription expiration warning dialog.
  ///
  /// Returns a Future that completes when the dialog is dismissed.
  static Future<void> showWarningDialog({
    required BuildContext context,
    required Authenticate authenticate,
    VoidCallback? onSubscribeNow,
  }) async {
    if (!context.mounted) return;

    final daysRemaining = authenticate.subscriptionDaysRemaining ?? 0;

    // Mark as shown before displaying
    if (authenticate.ownerPartyId != null) {
      await markAsShownToday(authenticate.ownerPartyId!);
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(dialogContext).colorScheme.error,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Subscription Expiring!',
                style: Theme.of(dialogContext).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  dialogContext,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    dialogContext,
                  ).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: Theme.of(dialogContext).colorScheme.error,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} remaining',
                          style: Theme.of(dialogContext)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  dialogContext,
                                ).colorScheme.error,
                              ),
                        ),
                        Text(
                          'Your subscription is about to expire',
                          style: Theme.of(dialogContext).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To continue using GrowERP without interruption, '
              'please renew your subscription before it expires.',
            ),
            const SizedBox(height: 12),
            const Text(
              '• All your data will be preserved\n'
              '• Access to all features continues\n'
              '• No additional setup required',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Remind Me Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onSubscribeNow?.call();
            },
            icon: const Icon(Icons.credit_card),
            label: const Text('Subscribe Now'),
          ),
        ],
      ),
    );
  }

  /// Convenience method to check and show warning if needed.
  ///
  /// Returns true if the dialog was shown, false otherwise.
  static Future<bool> showWarningIfNeeded({
    required BuildContext context,
    required Authenticate? authenticate,
    VoidCallback? onSubscribeNow,
  }) async {
    if (authenticate == null) return false;

    final shouldShow = await shouldShowWarning(authenticate);
    if (shouldShow && context.mounted) {
      // Small delay to ensure navigation is complete
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        await showWarningDialog(
          context: context,
          authenticate: authenticate,
          onSubscribeNow: onSubscribeNow,
        );
        return true;
      }
    }
    return false;
  }
}
