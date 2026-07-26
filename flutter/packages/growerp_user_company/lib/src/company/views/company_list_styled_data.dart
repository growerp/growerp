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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../company.dart';
import 'rest_request_stats_dialog.dart';

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
  var applicationId = context.read<String>();
  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        child: company.image != null
            ? Image.memory(company.image!)
            : Text(
                applicationId == 'AppSupport'
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
        applicationId == 'AppSupport'
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
    cells.add(SizedBox(
      key: Key('item$index'),
      child: Text(
        applicationId == 'AppSupport'
            ? (company.partyId ?? '')
            : (company.pseudoId ?? ''),
        key: Key('id$index'),
      ),
    ));

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

    // VAT/SLS: both are optional, show nothing rather than 'null'
    final perc = (company.vatPerc != null && company.vatPerc != Decimal.zero)
        ? company.vatPerc
        : company.salesPerc;
    cells.add(Text(perc?.toString() ?? '', key: Key('perc$index')));
  }

  // Actions (both phone and desktop)
  cells.add(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key("stats$index"),
          icon: const Icon(Icons.bar_chart),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return RestRequestStatsDialog(company: company);
              },
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          key: Key("delete$index"),
          icon: const Icon(Icons.delete_forever),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            bloc.add(CompanyDelete(company.copyWith(image: null)));
          },
        ),
      ],
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
