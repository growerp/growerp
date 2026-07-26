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
