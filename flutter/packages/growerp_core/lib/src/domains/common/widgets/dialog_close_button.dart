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
import 'package:go_router/go_router.dart';

/// Premium dialog close button with subtle styling that matches the app's design system.
class DialogCloseButton extends StatelessWidget {
  const DialogCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('cancel'),
          onTap: () {
            // For dialogs (opened via showDialog), Navigator.canPop() is true
            // and Navigator.pop() correctly closes the dialog overlay.
            // For GoRouter-pushed routes (e.g. /findoc inside a ShellRoute),
            // the ShellRoute's Navigator may only have one page, so canPop()
            // returns false.  Fall back to GoRouter's context.pop() which
            // correctly pops the GoRouter route back to the previous location.
            // If GoRouter also has nothing to pop (e.g. a top-level page like
            // a profile view), navigate to the root instead.
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.close,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
