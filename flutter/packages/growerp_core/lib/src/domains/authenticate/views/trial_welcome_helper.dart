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

/// Helper class for managing trial welcome dialog display.
///
/// Consolidates the trial welcome logic that was previously duplicated
/// in both TenantSetupDialog and LoginDialog.
class TrialWelcomeHelper {
  /// SharedPreferences key prefix for tracking shown state
  static const String _keyPrefix = 'trial_welcome_shown_';

  /// Check if trial welcome dialog should be shown for this tenant.
  ///
  /// Returns true if:
  /// - The tenant is not GROWERP (system tenant)
  /// - The trial welcome hasn't been shown yet for this tenant (local check)
  /// - The trial is fresh (subscriptionDaysRemaining is close to evaluationDays)
  ///
  /// The fresh trial check prevents showing the welcome on a second device
  /// when the trial was already started on another device.
  static Future<bool> shouldShowTrialWelcome(Authenticate? authenticate) async {
    if (authenticate?.ownerPartyId == null ||
        authenticate!.ownerPartyId == 'GROWERP') {
      return false;
    }

    // Check if trial is fresh (started recently)
    // If significant time has passed, the welcome was likely shown on another device
    final evaluationDays = authenticate.evaluationDays ?? 14;
    final daysRemaining = authenticate.subscriptionDaysRemaining ?? 0;

    // Allow 1 day tolerance for timezone differences and same-day logins
    // Only show welcome if we're within 1 day of the full evaluation period
    if (daysRemaining < evaluationDays - 1) {
      // Trial is not fresh - more than 1 day has passed since it started
      // Don't show welcome even if not marked as shown on this device
      return false;
    }

    // Check local storage for this device
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${authenticate.ownerPartyId}';
    return !(prefs.getBool(key) ?? false);
  }

  /// Mark the trial welcome dialog as shown for this tenant.
  static Future<void> markAsShown(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$ownerPartyId', true);
  }

  /// Show the trial welcome dialog.
  ///
  /// This is a consolidated version of the trial welcome dialog that was
  /// duplicated in TenantSetupDialog and LoginDialog.
  ///
  /// Returns a Future that completes when the dialog is dismissed.
  static Future<void> showTrialWelcomeDialog({
    required BuildContext context,
    required Authenticate authenticate,
  }) async {
    if (!context.mounted) return;

    // Mark as shown before displaying
    if (authenticate.ownerPartyId != null) {
      await markAsShown(authenticate.ownerPartyId!);
    }

    // Get user and company info
    final userName =
        '${authenticate.user?.firstName ?? ''} ${authenticate.user?.lastName ?? ''}'
            .trim();
    final companyName = authenticate.company?.name ?? 'Your Company';
    final userEmail = authenticate.user?.email ?? '';
    final evaluationDays = authenticate.evaluationDays ?? 14;
    final trialEndDate = DateTime.now().add(Duration(days: evaluationDays));
    final formattedEndDate =
        '${trialEndDate.day}/${trialEndDate.month}/${trialEndDate.year}';

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: Theme.of(dialogContext).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome to GrowERP!',
                style: Theme.of(dialogContext).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company and User info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    dialogContext,
                  ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: Theme.of(dialogContext).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            companyName,
                            style: Theme.of(dialogContext).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(dialogContext).colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userName.isNotEmpty ? userName : 'Administrator',
                            style: Theme.of(dialogContext).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (userEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Theme.of(dialogContext).colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userEmail,
                              style: Theme.of(dialogContext).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      dialogContext,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Trial info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    dialogContext,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$evaluationDays-Day Free Trial',
                            style: Theme.of(dialogContext).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Expires: $formattedEndDate',
                            style: Theme.of(dialogContext).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    dialogContext,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Full access to all features:',
                style: Theme.of(dialogContext).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                '✓ Manage products and inventory\n'
                '✓ Process orders and invoices\n'
                '✓ Track customers and leads\n'
                '✓ Generate reports and analytics',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 8),
              Text(
                'No credit card required during trial.',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            key: const Key('startTrial'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  /// Convenience method to check and show trial welcome if needed.
  ///
  /// Returns true if the dialog was shown, false otherwise.
  static Future<bool> showTrialWelcomeIfNeeded({
    required BuildContext context,
    required Authenticate? authenticate,
  }) async {
    if (authenticate == null) return false;

    final shouldShow = await shouldShowTrialWelcome(authenticate);
    if (shouldShow && context.mounted) {
      await showTrialWelcomeDialog(
        context: context,
        authenticate: authenticate,
      );
      return true;
    }
    return false;
  }
}
