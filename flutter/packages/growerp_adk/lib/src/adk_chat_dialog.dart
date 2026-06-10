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
import 'adk_chat_view.dart';

/// Wraps [AdkChatView] in a resizable dialog.
///
/// Use [AdkChatDialog.show] to display it, or instantiate directly inside
/// [showDialog]. The dialog inherits the caller's [BuildContext] so all
/// BLoC providers (AuthBloc, MenuConfigBloc) remain accessible.
class AdkChatDialog extends StatelessWidget {
  final List<ChatMenuEntry> menuItems;
  const AdkChatDialog({super.key, this.menuItems = const []});

  static Future<void> show(
    BuildContext context, {
    List<ChatMenuEntry> menuItems = const [],
  }) => showDialog<void>(
        context: context,
        builder: (_) => AdkChatDialog(menuItems: menuItems),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColoredBox(
              color: cs.primaryContainer,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.smart_toy, color: cs.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Assistant',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onPrimaryContainer),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(child: AdkChatView(menuItems: menuItems)),
          ],
        ),
      ),
    );
  }
}
