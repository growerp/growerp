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

import 'popup.dart';

/// dialog returns true when continue, false when cancelled
confirmDialog(BuildContext context, String title, String content) {
  // set up the buttons
  Widget cancelButton = OutlinedButton(
    child: const Text("Cancel", key: Key('cancel')),
    onPressed: () {
      Navigator.of(context).pop(false);
    },
  );
  Widget continueButton = OutlinedButton(
    child: const Text("Continue", key: Key('continue')),
    onPressed: () {
      Navigator.of(context).pop(true);
    },
  );

  // set up the AlertDialog
  Dialog dialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: popUp(
          height: 220,
          width: 400,
          context: context,
          title: title,
          child: Center(
            child: Column(children: [
              const SizedBox(height: 20),
              Text(content,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(children: [
                cancelButton,
                const SizedBox(width: 20),
                Expanded(child: continueButton)
              ]),
            ]),
          )));

  // show the dialog
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}
