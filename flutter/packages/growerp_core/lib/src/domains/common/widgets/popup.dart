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
import '../../../../growerp_core.dart';

/// Premium popup dialog with gradient header matching the app's design system.
Widget popUp({
  Widget? child,
  String title = '',
  double height = 400,
  double? width,
  double padding = 10,
  bool? closeButton = true,
  List<Widget>? actions,
  required BuildContext context,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  if (width == null) {
    isPhone(context) ? width = 450 : width = 700;
  }
  return Stack(
    clipBehavior: Clip.none,
    children: [
      SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            // Premium gradient header matching navigation rail and theme picker
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      title,
                      key: const Key('topHeader'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (actions != null)
                    Positioned(
                      right: closeButton == true ? 40 : 10,
                      top: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Material(
                color: Theme.of(context).brightness == Brightness.dark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Padding(padding: EdgeInsets.all(padding), child: child),
              ),
            ),
          ],
        ),
      ),
      if (closeButton == true)
        const Positioned(top: 15, right: 15, child: DialogCloseButton()),
    ],
  );
}
