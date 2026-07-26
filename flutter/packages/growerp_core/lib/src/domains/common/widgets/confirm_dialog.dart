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
import 'package:growerp_core/l10n/generated/core_localizations.dart';

import 'popup.dart';

/// dialog returns true when continue, false when cancelled
Future<bool?> confirmDialog(
  BuildContext context,
  String title,
  String content,
) {
  final localizations = CoreLocalizations.of(context)!;

  // show the dialog - buttons must be created inside builder to use dialog's context
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      // set up the buttons with dialog's context
      Widget cancelButton = OutlinedButton(
        child: Text(localizations.cancel, key: const Key('cancel')),
        onPressed: () {
          Navigator.of(dialogContext).pop(false);
        },
      );
      Widget continueButton = OutlinedButton(
        child: Text(localizations.continueButton, key: const Key('continue')),
        onPressed: () {
          Navigator.of(dialogContext).pop(true);
        },
      );

      // set up the AlertDialog
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          height: 220,
          width: 400,
          context: dialogContext,
          title: title,
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(content),
                const SizedBox(height: 20),
                Row(
                  children: [
                    cancelButton,
                    const SizedBox(width: 20),
                    Expanded(child: continueButton),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
