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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

/// Returns column definitions for GL account list based on device type
List<StyledColumn> getGlAccountListColumns(
  BuildContext context,
  OrderAccountingLocalizations localizations,
) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.accountCode, flex: 2),
      StyledColumn(header: localizations.accountName, flex: 3),
      StyledColumn(header: localizations.debit, flex: 2),
      StyledColumn(header: localizations.credit, flex: 2),
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    StyledColumn(header: localizations.accountCode, flex: 2),
    StyledColumn(header: localizations.accountName, flex: 3),
    StyledColumn(header: localizations.accountClass, flex: 2),
    StyledColumn(header: localizations.accountType, flex: 2),
    StyledColumn(header: localizations.debit, flex: 2),
    StyledColumn(header: localizations.credit, flex: 2),
  ];
}

/// Returns row data for GL account list
List<Widget> getGlAccountListRow({
  required BuildContext context,
  required GlAccount glAccount,
  required int index,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  // Calculate posted balance for display
  String postedBalance =
      glAccount.postedBalance == null ||
          glAccount.postedBalance.toString() == '0'
      ? ''
      : Constant.numberFormat.format(
          Decimal.parse(glAccount.postedBalance!.toString()),
        );

  // Avatar
  cells.add(
    CircleAvatar(
      radius: 16,
      child: Text(
        glAccount.accountCode == null
            ? '?'
            : glAccount.accountCode!.length >= 3
            ? glAccount.accountCode!.substring(0, 3)
            : glAccount.accountCode!,
        style: const TextStyle(fontSize: 10),
      ),
    ),
  );

  // Account code
  cells.add(Text(glAccount.accountCode ?? '', key: Key('code$index')));

  // Account name
  cells.add(
    Text(
      glAccount.accountName ?? '',
      key: Key('name$index'),
      overflow: TextOverflow.ellipsis,
    ),
  );

  if (isPhone) {
    // Debit column - show value if account is debit type
    cells.add(
      glAccount.isDebit == true
          ? Text(
              postedBalance,
              textAlign: TextAlign.right,
              key: Key('debit$index'),
            )
          : glAccount.isDebit == null
          ? Text(
              glAccount.postedDebits?.toString() ?? '',
              textAlign: TextAlign.right,
            )
          : const Text(''),
    );

    // Credit column - show value if account is credit type
    cells.add(
      glAccount.isDebit == false
          ? Text(
              postedBalance,
              textAlign: TextAlign.right,
              key: Key('credit$index'),
            )
          : glAccount.isDebit == null
          ? Text(
              glAccount.postedCredits?.toString() ?? '',
              textAlign: TextAlign.right,
            )
          : const Text(''),
    );
  } else {
    // Account class with (D) or (C) indicator
    cells.add(
      Text(
        "${glAccount.accountClass?.description ?? ''} "
        "${glAccount.isDebit != null
            ? glAccount.isDebit!
                  ? '(D)'
                  : '(C)'
            : ''} ",
        key: Key('class$index'),
      ),
    );

    // Account type
    cells.add(
      Text(glAccount.accountType?.description ?? '', key: Key('type$index')),
    );

    // Debit column
    cells.add(
      glAccount.isDebit == null
          ? Text(
              glAccount.postedDebits?.toString() ?? '',
              textAlign: TextAlign.right,
            )
          : glAccount.isDebit == true
          ? Text(
              postedBalance,
              textAlign: TextAlign.right,
              key: Key('postedBalance$index'),
            )
          : const Text(''),
    );

    // Credit column
    cells.add(
      glAccount.isDebit == null
          ? Text(
              glAccount.postedCredits?.toString() ?? '',
              textAlign: TextAlign.right,
            )
          : glAccount.isDebit == false
          ? Text(
              postedBalance,
              textAlign: TextAlign.right,
              key: Key('postedBalance$index'),
            )
          : const Text(''),
    );
  }

  return cells;
}
