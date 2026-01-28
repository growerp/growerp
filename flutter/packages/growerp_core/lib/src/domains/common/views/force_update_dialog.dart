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
import 'package:url_launcher/url_launcher.dart';
import '../functions/get_backend_url.dart';
import '../constant.dart';

/// A non-dismissible dialog that prompts the user to update the app
/// when a force update is required.
class ForceUpdateDialog extends StatelessWidget {
  final ForceUpdateInfo forceUpdateInfo;

  const ForceUpdateDialog({super.key, required this.forceUpdateInfo});

  /// Shows the force update dialog as a full-screen non-dismissible dialog.
  /// Uses GoRouter's navigator context to ensure we have a valid Navigator.
  /// Uses useRootNavigator: true to prevent dismissal during router rebuilds.
  static Future<void> show(BuildContext context, ForceUpdateInfo info) async {
    // First check if context has a Navigator ancestor
    final hasNavigator = Navigator.maybeOf(context) != null;

    if (hasNavigator) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true, // Prevents dismissal during router rebuilds
        builder: (dialogContext) => ForceUpdateDialog(forceUpdateInfo: info),
      );
    }

    // If no navigator in this context, try the global navigator key
    final navigatorState = Constant.navigatorKey.currentState;
    if (navigatorState != null) {
      return showDialog(
        context: navigatorState.context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => ForceUpdateDialog(forceUpdateInfo: info),
      );
    }

    // Last resort: wait a frame and try again with the same context
    // This can happen during app startup before Navigator is ready
    debugPrint('ForceUpdateDialog: Navigator not available, deferring...');
    await Future.delayed(const Duration(milliseconds: 100));

    // After delay, try again - check if context is still mounted first
    if (context.mounted && Navigator.maybeOf(context) != null) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => ForceUpdateDialog(forceUpdateInfo: info),
      );
    }

    debugPrint(
      'ForceUpdateDialog: Could not show dialog - no Navigator available',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevents back button from dismissing
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Required',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of the app is available.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVersionRow(
                    'Your version:',
                    forceUpdateInfo.currentVersion ?? 'Unknown',
                    Icons.phone_android,
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildVersionRow(
                    'Required version:',
                    forceUpdateInfo.minVersion ?? 'Latest',
                    Icons.new_releases,
                    theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please update to continue using the app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            key: const Key('updateNowButton'),
            onPressed: () => _launchUpdateUrl(),
            icon: const Icon(Icons.download),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(
    String label,
    String version,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          version,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUpdateUrl() async {
    final updateUrl = forceUpdateInfo.updateUrl;
    if (updateUrl != null && updateUrl.isNotEmpty) {
      final uri = Uri.parse(updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

/// A full-screen blocking widget that requires the user to update the app.
/// Used as an overlay when force update is required, preventing any app interaction.
class ForceUpdateScreen extends StatelessWidget {
  final ForceUpdateInfo forceUpdateInfo;

  const ForceUpdateScreen({super.key, required this.forceUpdateInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevents back button from dismissing
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.system_update,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Update Required',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A new version of the app is available.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildVersionRow(
                              'Your version:',
                              forceUpdateInfo.currentVersion ?? 'Unknown',
                              Icons.phone_android,
                              theme,
                            ),
                            const SizedBox(height: 12),
                            _buildVersionRow(
                              'Required version:',
                              forceUpdateInfo.minVersion ?? 'Latest',
                              Icons.new_releases,
                              theme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Please update to continue using the app.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('updateNowButton'),
                        onPressed: () => _launchUpdateUrl(),
                        icon: const Icon(Icons.download),
                        label: const Text('Update Now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionRow(
    String label,
    String version,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          version,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUpdateUrl() async {
    final updateUrl = forceUpdateInfo.updateUrl;
    if (updateUrl != null && updateUrl.isNotEmpty) {
      final uri = Uri.parse(updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
