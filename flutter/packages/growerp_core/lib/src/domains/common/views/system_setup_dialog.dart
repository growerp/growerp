/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../functions/functions.dart';

/// Key for storing Gemini API key in SharedPreferences
const String kGeminiApiKeyPref = 'gemini_api_key';

/// System Setup Screen for configuring AI and other system settings
///
/// This is a full-screen widget that can be displayed as a menu page.
class SystemSetupDialog extends StatefulWidget {
  const SystemSetupDialog({super.key});

  /// Get the stored Gemini API key
  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kGeminiApiKeyPref);
  }

  /// Save the Gemini API key
  static Future<void> saveGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kGeminiApiKeyPref, apiKey);
  }

  @override
  State<SystemSetupDialog> createState() => _SystemSetupDialogState();
}

class _SystemSetupDialogState extends State<SystemSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _geminiApiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final apiKey = await SystemSetupDialog.getGeminiApiKey();
    if (mounted) {
      setState(() {
        _geminiApiKeyController.text = apiKey ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _geminiApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await SystemSetupDialog.saveGeminiApiKey(_geminiApiKeyController.text);

      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Settings saved successfully',
          Theme.of(context).colorScheme.primary,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to save settings: $e',
          Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      key: const Key('SystemSetupDialog'),
      padding: EdgeInsets.all(isPhone ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'System Setup',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure AI and other system settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // AI Settings Section
                _aiSettingsSection(),
                const SizedBox(height: 32),

                // Save Button
                Center(child: _saveButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aiSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Enter your Google Gemini API key to enable AI-powered navigation. '
              'Get your key from the Google AI Studio.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('geminiApiKey'),
              controller: _geminiApiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'Enter your API key',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                      tooltip: _obscureApiKey ? 'Show key' : 'Hide key',
                    ),
                    if (_geminiApiKeyController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _geminiApiKeyController.clear());
                        },
                        tooltip: 'Clear',
                      ),
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                // API key is optional
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Get API Key from Google AI Studio'),
              onPressed: () {
                HelperFunctions.showMessage(
                  context,
                  'Visit: https://aistudio.google.com/apikey',
                  Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        key: const Key('saveSettings'),
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
        onPressed: _isSaving ? null : _saveSettings,
      ),
    );
  }
}
