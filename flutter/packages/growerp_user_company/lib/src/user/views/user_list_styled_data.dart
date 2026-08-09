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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:url_launcher/url_launcher.dart';

import '../user.dart';
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';

/// Returns column definitions for user list based on device type
List<StyledColumn> getUserListColumns(BuildContext context, {Role? role}) {
  final localizations = UserCompanyLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrInfo, flex: 4),
      if (role == null || role == Role.unknown)
        StyledColumn(header: localizations.role, flex: 2)
      else
        StyledColumn(header: localizations.company, flex: 3),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    StyledColumn(header: localizations.id, flex: 1),
    StyledColumn(header: localizations.name, flex: 2),
    StyledColumn(header: localizations.email, flex: 2),
    StyledColumn(header: localizations.tableHdrUrl, flex: 2),
    if (role == null || role == Role.unknown)
      StyledColumn(header: localizations.role, flex: 2)
    else
      StyledColumn(header: localizations.company, flex: 2),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for user list
List<Widget> getUserListRow({
  required BuildContext context,
  required User user,
  required int index,
  required Bloc bloc,
  Role? role,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        child: user.image != null
            ? Image.memory(user.image!)
            : Text(
                user.pseudoId == null ? '' : user.pseudoId!.lastChar(3),
                key: const Key('userItem'),
              ),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(user.pseudoId ?? '', key: Key('id$index')),
          Text(
            ("${user.firstName ?? ''} ${user.lastName ?? ''}").truncate(18),
            key: Key('name$index'),
          ),
          if (user.email != null)
            GestureDetector(
              onTap: () async =>
                  await launchUrl(Uri.parse('mailto:${user.email}')),
              child: Text(
                user.email.truncate(15),
                style: const TextStyle(decoration: TextDecoration.underline),
                key: Key('email$index'),
              ),
            )
          else if (user.url != null)
            GestureDetector(
              onTap: () async => await launchUrl(Uri.parse("${user.url}")),
              child: Text(
                user.url.truncate(15),
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  } else {
    // ID (the constant 'userItem' key must be present on desktop too —
    // tests count it to determine the number of rows)
    cells.add(
      SizedBox(
        key: const Key('userItem'),
        child: SizedBox(
          key: Key('item$index'),
          child: Text(user.pseudoId ?? '', key: Key('id$index')),
        ),
      ),
    );

    // Name
    cells.add(
      Text(
        "${user.firstName ?? ''} ${user.lastName ?? ''} ",
        key: Key('name$index'),
      ),
    );

    // Email
    cells.add(
      user.email != null
          ? GestureDetector(
              onTap: () async =>
                  await launchUrl(Uri.parse('mailto:${user.email}')),
              child: Text(
                user.email!,
                style: const TextStyle(decoration: TextDecoration.underline),
                key: Key('email$index'),
              ),
            )
          : Text(user.email ?? '', key: Key('email$index')),
    );

    // Url
    cells.add(
      user.url != null
          ? GestureDetector(
              onTap: () async => await launchUrl(Uri.parse(user.url!)),
              child: Text(
                user.url!,
                style: const TextStyle(decoration: TextDecoration.underline),
                key: Key('url$index'),
              ),
            )
          : Text('', key: Key('url$index')),
    );
  }

  // Role or Company (both phone and desktop)
  if (role == null || role == Role.unknown) {
    final roleType = _getRoleStatusType(user.role);
    cells.add(
      StatusChip(
        label: user.role != null ? user.role!.name : Role.unknown.name,
        type: roleType,
        size: StatusChipSize.small,
        key: Key('role$index'),
      ),
    );
  } else {
    cells.add(Text(user.company?.name ?? '', key: Key('companyName$index')));
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key("delete$index"),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        bloc.add(UserDelete(user.copyWith(image: null)));
      },
    ),
  );

  return cells;
}

/// Maps a Role to an appropriate StatusType for display
StatusType _getRoleStatusType(Role? role) {
  if (role == null) return StatusType.neutral;
  switch (role) {
    case Role.company:
      return StatusType.info;
    case Role.customer:
      return StatusType.success;
    case Role.lead:
      return StatusType.warning;
    case Role.supplier:
      return StatusType.info;
    case Role.unknown:
      return StatusType.neutral;
  }
}
