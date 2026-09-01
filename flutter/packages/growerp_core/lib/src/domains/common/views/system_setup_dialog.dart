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

import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growerp_core/growerp_core.dart';

/// System Setup on one page: AI ([SystemSetupAiView]) above the email server
/// ([SystemSetupEmailView]), each saving its own settings.
///
/// Apps that carry System Setup as a menu item with children show those views
/// as tabs instead, next to the guides ([GuideList]); this page is what an app
/// without those tabs gets, and what the ADK chat opens as a modal dialog.
class SystemSetupDialog extends StatelessWidget {
  /// When shown modally (e.g. from the ADK chat) rather than as a full-screen
  /// menu route: adds a Cancel button and pops on a successful save.
  final bool inDialog;
  const SystemSetupDialog({super.key, this.inDialog = false});

  /// Backward-compat: returns Gemini API key.
  /// Checks llmConfigs list first, then legacy geminiApiKey field, then SharedPreferences.
  static Future<String?> getGeminiApiKey(RestClient? restClient) async {
    if (restClient != null) {
      try {
        final s = await restClient.getSystemSettings();
        final geminiCfg = s.llmConfigs
            .where((lc) => lc.llmProvider == 'gemini')
            .firstOrNull;
        if (geminiCfg?.apiKey != null && geminiCfg!.apiKey!.isNotEmpty) {
          return geminiCfg.apiKey;
        }
        if (s.geminiApiKey != null && s.geminiApiKey!.isNotEmpty) {
          return s.geminiApiKey;
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key');
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    void pop() {
      if (inDialog) Navigator.of(context).pop();
    }

    return SingleChildScrollView(
      key: const Key('SystemSetupDialog'),
      padding: EdgeInsets.all(isPhone ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isPhone ? 600 : 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'System Settings',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                CoreLocalizations.of(context)!.configureLlmProviderApiKeys,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SystemSetupAiView(standalone: false, onSaved: pop),
              const SizedBox(height: 24),
              SystemSetupEmailView(standalone: false, onSaved: pop),
              if (inDialog) ...[
                const SizedBox(height: 24),
                Center(
                  child: OutlinedButton(
                    key: const Key('cancelSettings'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(CoreLocalizations.of(context)!.cancel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
