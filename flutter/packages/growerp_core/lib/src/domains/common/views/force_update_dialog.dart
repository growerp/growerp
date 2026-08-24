/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'reload_web_stub.dart'
    if (dart.library.js_interop) 'reload_web_web.dart';

import 'package:growerp_core/growerp_core.dart';

bool get _isLinux {
  if (kIsWeb) return false;
  try {
    return Platform.isLinux;
  } catch (_) {
    return false;
  }
}

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
            SizedBox(width: 12),
            Expanded(
              child: Text(
                CoreLocalizations.of(context)!.updateRequired,
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
              CoreLocalizations.of(context)!.aNewVersionIsAvailable,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
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
                  SizedBox(height: 8),
                  _buildVersionRow(
                    'Required version:',
                    forceUpdateInfo.minVersion ?? 'Latest',
                    Icons.new_releases,
                    theme,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              CoreLocalizations.of(context)!.pleaseUpdateToContinue,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_isLinux) ...[
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Run ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          children: [
                            TextSpan(
                              text: 'snap refresh',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const TextSpan(text: ' in the terminal.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isLinux)
            FilledButton.icon(
              key: const Key('updateNowButton'),
              onPressed: () => _launchUpdateUrl(),
              icon: const Icon(Icons.download),
              label: Text(CoreLocalizations.of(context)!.updateNow),
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
        SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4),
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
      await openExternalUrl(Uri.parse(updateUrl));
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
                      SizedBox(height: 24),
                      Text(
                        CoreLocalizations.of(context)!.updateRequired,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        CoreLocalizations.of(context)!.aNewVersionIsAvailable,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
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
                            SizedBox(height: 12),
                            _buildVersionRow(
                              'Required version:',
                              forceUpdateInfo.minVersion ?? 'Latest',
                              Icons.new_releases,
                              theme,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        CoreLocalizations.of(context)!.pleaseUpdateToContinue,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isLinux) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.terminal,
                                size: 22,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Run ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'snap refresh',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const TextSpan(text: ' in the terminal.'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (kIsWeb) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 22,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  CoreLocalizations.of(context)!.pressCtrlF5ToUpdate,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        FilledButton.icon(
                          key: const Key('updateNowButton'),
                          onPressed: () => reloadPage(),
                          icon: const Icon(Icons.refresh),
                          label: Text(CoreLocalizations.of(context)!.reloadNow),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ] else if (!_isLinux) ...[
                        SizedBox(height: 24),
                        FilledButton.icon(
                          key: const Key('updateNowButton'),
                          onPressed: () => _launchUpdateUrl(),
                          icon: const Icon(Icons.download),
                          label: Text(CoreLocalizations.of(context)!.updateNow),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
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
        SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4),
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
      await openExternalUrl(Uri.parse(updateUrl));
    }
  }
}
