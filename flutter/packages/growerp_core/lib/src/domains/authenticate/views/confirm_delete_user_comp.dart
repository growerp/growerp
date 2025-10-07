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
import 'package:growerp_models/growerp_models.dart';

import '../../domains.dart';

/// dialog returns true when company delete, false when not,
/// null when cancelled
///
Future<bool?> confirmDeleteUserComp(
  BuildContext context,
  UserGroup? userGroup,
) {
  final localizations = CoreLocalizations.of(context)!;
  List<Widget> actions = [
    Text(localizations.deleteWarning),
    const SizedBox(height: 20),
    OutlinedButton(
      child: Text(localizations.onlyUserDelete),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    ),
  ];
  if (userGroup == UserGroup.admin) {
    actions.add(const SizedBox(height: 10));
    actions.add(
      OutlinedButton(
        child: Text(localizations.userAndCompanyDelete),
        onPressed: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

  // show the dialog
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        child: popUp(
          height: 300,
          context: context,
          title: userGroup == UserGroup.admin
              ? localizations.deleteYourselfAndCompany
              : localizations.deleteYourself,
          child: Column(children: actions),
        ),
      );
    },
  );
}
