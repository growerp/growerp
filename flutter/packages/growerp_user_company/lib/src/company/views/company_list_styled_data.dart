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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../company.dart';

/// Returns column definitions for company list based on device type
List<StyledColumn> getCompanyListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: 'ID', flex: 1),
      StyledColumn(header: 'Info', flex: 4),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: 'ID', flex: 1),
    StyledColumn(header: 'Name', flex: 2),
    StyledColumn(header: 'Role', flex: 1),
    StyledColumn(header: 'Email', flex: 2),
    StyledColumn(header: 'Phone', flex: 1),
    StyledColumn(header: 'VAT/SLS', flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for company list
List<Widget> getCompanyListRow({
  required BuildContext context,
  required Company company,
  required int index,
  required Bloc bloc,
}) {
  bool isPhone = isAPhone(context);
  var classificationId = context.read<String>();
  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        child: company.image != null
            ? Image.memory(company.image!)
            : Text(
                classificationId == 'AppSupport'
                    ? company.partyId!.lastChar(3)
                    : company.pseudoId == null
                    ? ''
                    : company.pseudoId!.lastChar(3),
              ),
      ),
    );

    // ID
    cells.add(
      Text(
        classificationId == 'AppSupport'
            ? (company.partyId ?? '')
            : (company.pseudoId ?? ''),
        key: Key('id$index'),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(company.name.truncate(20), key: Key('name$index')),
          Text(company.email.truncate(20), key: const Key("companyEmail")),
        ],
      ),
    );
  } else {
    // ID
    cells.add(
      Text(
        classificationId == 'AppSupport'
            ? (company.partyId ?? '')
            : (company.pseudoId ?? ''),
        key: Key('id$index'),
      ),
    );

    // Name
    cells.add(Text(company.name ?? '', key: Key('name$index')));

    // Role with StatusChip
    cells.add(
      StatusChip(
        label: company.role?.name ?? 'unknown',
        type: _getCompanyRoleStatusType(company.role),
        size: StatusChipSize.small,
        key: Key('role$index'),
      ),
    );

    // Email
    cells.add(Text(company.email ?? '', key: Key('email$index')));

    // Phone
    cells.add(Text(company.telephoneNr ?? '', key: Key('telephone$index')));

    // VAT/SLS
    cells.add(
      Text(
        company.vatPerc != Decimal.parse("0")
            ? company.vatPerc.toString()
            : company.salesPerc.toString(),
        key: Key('perc$index'),
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
        bloc.add(CompanyDelete(company.copyWith(image: null)));
      },
    ),
  );

  return cells;
}

/// Maps a Role to an appropriate StatusType for company display
StatusType _getCompanyRoleStatusType(Role? role) {
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
