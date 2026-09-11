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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

/// Column definitions for the cash book list, per device type
List<StyledColumn> getCashBookListColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  if (isAPhone(context)) {
    return [
      const StyledColumn(header: '', flex: 1), // direction avatar
      StyledColumn(header: localizations.description, flex: 4),
      StyledColumn(header: localizations.amount, flex: 2),
    ];
  }
  return [
    const StyledColumn(header: '', flex: 1), // direction avatar
    StyledColumn(header: localizations.date, flex: 2),
    StyledColumn(header: localizations.description, flex: 4),
    StyledColumn(header: localizations.cashCategory, flex: 3),
    StyledColumn(header: localizations.tableHdrCustomerSupplier, flex: 3),
    StyledColumn(header: localizations.cashSource, flex: 1),
    StyledColumn(header: localizations.amount, flex: 2),
  ];
}

String cashBookSourceLabel(
  String source,
  OrderAccountingLocalizations localizations,
) => switch (source) {
  'invoice' => localizations.cashSourceInvoice,
  'payment' => localizations.cashSourcePayment,
  _ => localizations.cashSourceManual,
};

String cashBookPartyName(CashBookEntry entry) =>
    entry.otherCompany?.name ??
    (entry.otherUser == null
        ? ''
        : '${entry.otherUser!.firstName ?? ''} ${entry.otherUser!.lastName ?? ''}'
              .trim());

/// Row cells for one cash book entry
List<Widget> getCashBookListRow({
  required BuildContext context,
  required CashBookEntry entry,
  required int index,
  required String currencyId,
}) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  bool isPhone = isAPhone(context);
  final color = entry.isIncome ? colorScheme.success : colorScheme.danger;
  final date = entry.date == null
      ? ''
      : DateFormat('yyyy-MM-dd').format(entry.date!);
  final amount = Text(
    '${entry.isIncome ? '+' : '-'}${entry.amount.currency(currencyId: currencyId)}',
    key: Key('amount$index'),
    textAlign: TextAlign.right,
    style: TextStyle(color: color, fontWeight: FontWeight.w600),
  );
  final avatar = SizedBox(
    key: const Key('cashBookItem'),
    child: CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(
        entry.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
        size: 16,
        color: color,
      ),
    ),
  );

  if (isPhone) {
    return [
      avatar,
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            entry.description.isEmpty
                ? (entry.category?.accountName ?? '')
                : entry.description,
            key: Key('name$index'),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            '$date  ${entry.category?.accountName ?? ''}',
            key: Key('category$index'),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      amount,
    ];
  }

  return [
    avatar,
    Text(date, key: Key('date$index')),
    Text(
      entry.description,
      key: Key('name$index'),
      overflow: TextOverflow.ellipsis,
    ),
    Text(
      entry.category?.accountName ?? '',
      key: Key('category$index'),
      overflow: TextOverflow.ellipsis,
    ),
    Text(
      cashBookPartyName(entry),
      key: Key('party$index'),
      overflow: TextOverflow.ellipsis,
    ),
    Text(
      cashBookSourceLabel(entry.source, localizations),
      key: Key('source$index'),
    ),
    amount,
  ];
}
