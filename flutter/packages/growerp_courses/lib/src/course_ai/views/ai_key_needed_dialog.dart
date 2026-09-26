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

import 'package:growerp_courses/l10n/generated/courses_localizations.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';

/// The free AI allowance (system key) is used up, or there is no key at all:
/// explain and offer the AI settings to enter the company's own API key.
Future<void> showAiKeyNeededDialog(
  BuildContext context,
  String? message,
) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('aiKeyNeededDialog'),
      title: Text(CoursesLocalizations.of(context)!.courses_aiKeyNeeded),
      content: Text(
        '${message ?? CoursesLocalizations.of(context)!.courses_allowanceUsedUp}\n\n'
        '${CoursesLocalizations.of(context)!.courses_addKeyToContinue}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(CoursesLocalizations.of(context)!.courses_later),
        ),
        ElevatedButton(
          key: const Key('aiKeyOpenSettings'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(CoursesLocalizations.of(context)!.courses_addApiKey),
        ),
      ],
    ),
  );
  if (open != true || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: dialogContext,
        title: CoursesLocalizations.of(context)!.courses_aiSettings,
        width: 700,
        height: MediaQuery.of(dialogContext).size.height * 0.85,
        child: SystemSetupAiView(onSaved: () => Navigator.pop(dialogContext)),
      ),
    ),
  );
}
