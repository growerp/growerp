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
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_framework.dart';
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
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'AI Assistant',
        width: isPhone ? 400 : 600,
        height: size.height * 0.85,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AdkChatView(menuItems: menuItems),
          ),
        ),
      ),
    );
  }
}
