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
