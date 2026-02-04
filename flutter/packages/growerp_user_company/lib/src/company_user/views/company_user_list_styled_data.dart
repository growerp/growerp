/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../company_user.dart';

/// Returns column definitions for company user list based on device type
List<StyledColumn> getCompanyUserListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: 'ID', flex: 1),
      StyledColumn(header: 'T', flex: 1), // Type
      StyledColumn(header: 'Info', flex: 5),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: 'ID', flex: 1),
    StyledColumn(header: 'T', flex: 1), // Type
    StyledColumn(header: 'Name', flex: 3),
    StyledColumn(header: 'Role', flex: 1),
    StyledColumn(header: 'Email', flex: 2),
    StyledColumn(header: 'Phone', flex: 1),
    StyledColumn(header: 'Location', flex: 2),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for company user list
List<Widget> getCompanyUserListRow({
  required BuildContext context,
  required CompanyUser companyUser,
  required int index,
  required Bloc bloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        child: companyUser.image != null
            ? Image.memory(companyUser.image!)
            : Text(
                companyUser.pseudoId == null
                    ? ''
                    : companyUser.pseudoId!.lastChar(3),
              ),
      ),
    );

    // ID
    cells.add(Text(companyUser.pseudoId ?? '', key: Key('id$index')));

    // Type indicator
    cells.add(
      Text(
        companyUser.type == PartyType.company
            ? 'O'
            : companyUser.type == PartyType.user
            ? 'P'
            : '?',
        key: Key('type$index'),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("${companyUser.name.truncate(20)} ", key: Key('name$index')),
          Text(companyUser.email.truncate(20), key: const Key("companyEmail")),
        ],
      ),
    );
  } else {
    // ID
    cells.add(Text(companyUser.pseudoId ?? '', key: Key('id$index')));

    // Type indicator
    cells.add(
      Text(
        companyUser.type == PartyType.company
            ? 'O'
            : companyUser.type == PartyType.user
            ? 'P'
            : '?',
        key: Key('type$index'),
      ),
    );

    // Name
    cells.add(Text(companyUser.name ?? '', key: Key('name$index')));

    // Role
    cells.add(
      Text(
        companyUser.role != null ? companyUser.role!.value : Role.unknown.value,
        key: Key('role$index'),
      ),
    );

    // Email
    cells.add(Text(companyUser.email ?? '', key: Key('email$index')));

    // Phone
    cells.add(Text(companyUser.telephoneNr ?? '', key: Key('telephone$index')));

    // Location
    cells.add(
      Text(
        "${companyUser.address?.country ?? ''} ${companyUser.address?.city ?? ''}",
        key: Key('location$index'),
      ),
    );
  }

  // Delete action (both phone and desktop)
  cells.add(
    IconButton(
      key: Key("delete$index"),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        bloc.add(const CompanyUserDelete());
      },
    ),
  );

  return cells;
}
