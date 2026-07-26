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
import '../../domains.dart';

/// Premium popup dialog without scaffold, with gradient header matching the app's design system.
Widget popUpDialogNoScaffold({
  required BuildContext context,
  required List<Widget> children,
  String title = '',
  double height = 400,
  double width = 400,
  Key key = const Key('popUp'),
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return Dialog(
    insetPadding: const EdgeInsets.all(10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: Column(
            children: [
              // Premium gradient header
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
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: colorScheme.onSurface,
                    ),
                  ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(children: children),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(top: 10, right: 10, child: DialogCloseButton()),
      ],
    ),
  );
}
