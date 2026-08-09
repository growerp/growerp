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
import 'package:decimal/decimal.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

List<StyledColumn> getFinDocItemListColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  return [
    StyledColumn(header: localizations.tableHdrNumber, flex: 1),
    StyledColumn(header: localizations.tableHdrProductId, flex: 2),
    StyledColumn(header: localizations.description, flex: 4),
    if (!isPhone) StyledColumn(header: localizations.item, flex: 2),
    StyledColumn(header: localizations.tableHdrQuantity, flex: 2),
    if (!isPhone) StyledColumn(header: localizations.price, flex: 2),
    if (!isPhone) StyledColumn(header: localizations.tableHdrSubtotal, flex: 2),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getFinDocItemListRow({
  required BuildContext context,
  required FinDocItem item,
  required int index,
  required String currencyId,
  required ItemType itemType,
  required bool readOnly,
  required void Function() onDelete,
}) {
  bool isPhone = isAPhone(context);
  return [
    CircleAvatar(child: Text(item.itemSeqId.toString())),
    Text("${item.product?.pseudoId}", key: Key('itemProductId$index')),
    Text(item.description ?? '', key: Key('itemDescription$index')),
    if (!isPhone) Text(itemType.itemTypeName, key: Key('itemType$index')),
    if (item.rentalFromDate != null)
      Text(
        item.rentalFromDate.toLocalizedDateOnly(context),
        key: Key('fromDate$index'),
      )
    else
      Text(
        item.quantity == null
            ? Decimal.zero.toString()
            : item.quantity.toString(),
        textAlign: TextAlign.right,
        key: Key('itemQuantity$index'),
      ),
    if (!isPhone)
      Text(
        item.price == null
            ? Decimal.fromInt(0).currency(currencyId: currencyId)
            : item.price.currency(currencyId: currencyId),
        textAlign: TextAlign.right,
        key: Key('itemPrice$index'),
      ),
    if (!isPhone)
      Text(
        item.price == null
            ? Decimal.zero.currency(currencyId: currencyId)
            : (item.price! * (item.quantity ?? Decimal.one)).currency(
                currencyId: currencyId,
              ),
        textAlign: TextAlign.right,
      ),
    if (!readOnly)
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.delete_forever),
        padding: EdgeInsets.zero,
        key: Key("itemDelete$index"),
        onPressed: onDelete,
      )
    else
      const SizedBox.shrink(),
  ];
}

List<StyledColumn> getFinDocItemListShipmentColumns(
  BuildContext context,
  FinDoc finDoc,
) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  return [
    StyledColumn(header: localizations.tableHdrNumber, flex: 1),
    StyledColumn(header: localizations.tableHdrProductId, flex: 2),
    StyledColumn(header: localizations.description, flex: 4),
    StyledColumn(header: localizations.tableHdrQuantity, flex: 2),
    if (finDoc.status == FinDocStatusVal.completed)
      StyledColumn(header: localizations.location, flex: 2),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getFinDocItemListShipmentRow({
  required BuildContext context,
  required FinDocItem item,
  required int index,
  required bool readOnly,
  required FinDocStatusVal? finDocStatus,
  required void Function() onDelete,
}) {
  return [
    CircleAvatar(child: Text((index + 1).toString())),
    Text("${item.product?.pseudoId}", key: Key('itemProductId$index')),
    Text(item.description ?? '', key: Key('itemDescription$index')),
    Text(
      item.quantity == null
          ? Decimal.zero.toString()
          : item.quantity.toString(),
      key: Key('itemQuantity$index'),
    ),
    if (finDocStatus == FinDocStatusVal.completed)
      Text(
        "${item.asset?.location?.locationName}",
        key: Key('itemLocation$index'),
      ),
    if (!readOnly)
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.delete_forever),
        padding: EdgeInsets.zero,
        key: Key("itemDelete$index"),
        onPressed: onDelete,
      )
    else
      const SizedBox.shrink(),
  ];
}

List<StyledColumn> getFinDocItemListTransactionColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  return [
    StyledColumn(header: localizations.glAccountLabel, flex: 2),
    StyledColumn(header: localizations.debit, flex: 2),
    StyledColumn(header: localizations.credit, flex: 2),
    StyledColumn(header: localizations.tableHdrProductId, flex: 2),
    if (!isPhone) StyledColumn(header: localizations.description, flex: 3),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getFinDocItemListTransactionRow({
  required BuildContext context,
  required FinDocItem item,
  required int index,
  required String currencyId,
  required bool readOnly,
  required void Function() onDelete,
}) {
  return [
    Text(item.glAccount!.accountCode ?? '??', key: Key('accountCode$index')),
    Text(
      (item.isDebit! ? item.price.currency(currencyId: currencyId) : ''),
      key: Key('debit$index'),
    ),
    Text(
      !item.isDebit! ? item.price.currency(currencyId: currencyId) : '',
      key: Key('credit$index'),
    ),
    Text(item.product?.pseudoId ?? '', key: Key('itemProductId$index')),
    if (!isAPhone(context))
      Text(item.product?.productName ?? '', key: Key('itemProductName$index')),
    if (!readOnly)
      IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.delete_forever, size: 20),
        key: Key("itemDelete$index"),
        onPressed: onDelete,
      )
    else
      const SizedBox.shrink(),
  ];
}
