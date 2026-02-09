/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:decimal/decimal.dart';

List<StyledColumn> getFinDocItemListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  return [
    const StyledColumn(header: '#', flex: 1),
    const StyledColumn(header: 'Product ID', flex: 2),
    const StyledColumn(header: 'Description', flex: 4),
    if (!isPhone) const StyledColumn(header: 'Item', flex: 2),
    const StyledColumn(header: 'Quantity', flex: 2),
    if (!isPhone) const StyledColumn(header: 'Price', flex: 2),
    if (!isPhone) const StyledColumn(header: 'SubTotal', flex: 2),
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
  return [
    const StyledColumn(header: '#', flex: 1),
    const StyledColumn(header: 'Product ID', flex: 2),
    const StyledColumn(header: 'Description', flex: 4),
    const StyledColumn(header: 'Quantity', flex: 2),
    if (finDoc.status == FinDocStatusVal.completed)
      const StyledColumn(header: 'Location', flex: 2),
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
  return [
    const StyledColumn(header: 'GL Account', flex: 2),
    const StyledColumn(header: 'Debit', flex: 2),
    const StyledColumn(header: 'Credit', flex: 2),
    const StyledColumn(header: 'Product ID', flex: 2),
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
