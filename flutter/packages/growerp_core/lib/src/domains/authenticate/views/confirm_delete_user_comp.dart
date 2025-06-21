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
import 'package:growerp_models/growerp_models.dart';

import '../../domains.dart';

/// dialog returns true when company delete, false when not,
/// null when cancelled
///
confirmDeleteUserComp(BuildContext context, UserGroup? userGroup) {
  List<Widget> actions = [
    const Text("Please note you will be blocked using the system."
        "\nThis cannot be undone!"),
    const SizedBox(height: 20),
    OutlinedButton(
        child: const Text("Only User delete"),
        onPressed: () {
          Navigator.of(context).pop(false);
        }),
  ];
  if (userGroup == UserGroup.admin) {
    actions.add(const SizedBox(height: 10));
    actions.add(OutlinedButton(
      child: const Text("User AND Company delete"),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    ));
  }

  // show the dialog
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25.0))),
          child: popUp(
              height: 300,
              context: context,
              title:
                  "Delete yourself ${userGroup == UserGroup.admin ? ' and opt. company?' : ''}",
              child: Column(
                children: actions,
              )));
    },
  );
}
