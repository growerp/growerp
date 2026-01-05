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
import 'package:go_router/go_router.dart';
import '../../../services/ai_navigation_service.dart';

/// AI-powered navigation dialog
///
/// Shows a text input for natural language prompts like "show open invoices"
/// and navigates to the appropriate screen.
class AiPromptDialog extends StatefulWidget {
  /// Gemini API key for AI navigation
  final String apiKey;

  /// Optional menu configuration for route-aware navigation
  /// When provided, the AI uses actual routes from the menu
  final dynamic menuConfiguration;

  /// Callback when navigation is successful (optional)
  final void Function(NavigationIntent)? onNavigate;

  const AiPromptDialog({
    super.key,
    required this.apiKey,
    this.menuConfiguration,
    this.onNavigate,
  });

  /// Show as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String apiKey,
    dynamic menuConfiguration,
    void Function(NavigationIntent)? onNavigate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiPromptDialog(
        apiKey: apiKey,
        menuConfiguration: menuConfiguration,
        onNavigate: onNavigate,
      ),
    );
  }

  @override
  State<AiPromptDialog> createState() => _AiPromptDialogState();
}

class _AiPromptDialogState extends State<AiPromptDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final AiNavigationService _aiService;

  bool _isLoading = false;
  String? _error;
  NavigationIntent? _lastIntent;

  // Recent prompts for quick access
  final List<String> _recentPrompts = [];

  @override
  void initState() {
    super.initState();
    _aiService = AiNavigationService(apiKey: widget.apiKey);
    // Configure with menu if available for route-aware navigation
    if (widget.menuConfiguration != null) {
      _aiService.setMenuConfiguration(widget.menuConfiguration);
    }
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    NavigationIntent intent;

    // Try AI first, then fallback to local search
    if (widget.apiKey.isNotEmpty) {
      intent = await _aiService.parsePrompt(prompt);
    } else {
      intent = _aiService.searchLocal(prompt);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _lastIntent = intent;
    });

    if (intent.isValid) {
      // Add to recent prompts
      if (!_recentPrompts.contains(prompt)) {
        _recentPrompts.insert(0, prompt);
        if (_recentPrompts.length > 5) {
          _recentPrompts.removeLast();
        }
      }

      if (widget.onNavigate != null) {
        // Close dialog and use custom navigation
        Navigator.of(context).pop();
        widget.onNavigate!(intent);
      } else {
        // Use route from intent if available, otherwise derive from widget name
        // GoRouter's onException handler will catch invalid routes
        final route = intent.route ?? _widgetNameToRoute(intent.widgetName);
        Navigator.of(context).pop();
        context.go(route);
      }
    } else {
      setState(() {
        _error =
            'Could not understand your request. Try:\n'
            '• "show invoices"\n'
            '• "open sales orders"\n'
            '• "chart of accounts"';
      });
    }
  }

  /// Convert widget name to route path
  String _widgetNameToRoute(String widgetName) {
    // Convert CamelCase to kebab-case
    final kebab = widgetName
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => '-${m.group(1)!.toLowerCase()}',
        )
        .substring(1); // Remove leading dash
    return '/$kebab';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('AI Navigation', style: theme.textTheme.titleLarge),
              ],
            ),
          ),

          // Input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _handleSubmit(),
              decoration: InputDecoration(
                hintText: 'What would you like to see?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _handleSubmit,
                      ),
              ),
            ),
          ),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),

          // Success info
          if (_lastIntent?.isValid == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastIntent!.explanation ??
                      'Navigating to ${_lastIntent!.widgetName}',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),

          // Quick suggestions
          if (_recentPrompts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('Show invoices'),
                  _buildSuggestionChip('Sales orders'),
                  _buildSuggestionChip('Chart of accounts'),
                  _buildSuggestionChip('Products'),
                ],
              ),
            ),

          // Recent prompts
          if (_recentPrompts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentPrompts
                        .map((p) => _buildSuggestionChip(p))
                        .toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _controller.text = text;
        _handleSubmit();
      },
    );
  }
}
