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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

// field headers
List<dynamic> getItemFieldNames(
    {int? itemIndex,
    String? classificationId,
    FinDoc? item,
    BuildContext? context}) {
  bool isPhone = isAPhone(context);
  if (isPhone)
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(3, 3, 0, 0),
        child: Text("Short\nID"),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${item!.docType} Id'),
          SizedBox(width: 10),
          Text(classificationId == 'AppHotel'
              ? 'Reserv. Date'
              : 'Creation Date'),
        ]),
        Text(item.sales ? 'Customer' : 'Supplier'),
        Row(
          children: [
            Text('Status'),
            SizedBox(width: 10),
            if (item.docType != FinDocType.shipment) Text('Total'),
            SizedBox(width: 10),
            Text('#Items'),
          ],
        ),
      ]),
      const Text(""),
    ];
  else
    return [
      Text('${item!.docType} Id'),
      Text(classificationId == 'AppHotel' ? 'Reserv. Date' : 'Creation Date'),
      Text(item.sales ? 'Customer' : 'Supplier'),
      if (item.docType != FinDocType.shipment)
        const Text(
          "Total",
          textAlign: TextAlign.right,
        ),
      const Text("Status"),
      const Text("Email Address"),
      const Text(""),
    ];
}

// field lengths perc of screenwidth can be larger than 100 %: horizontal
List<double> getItemFieldWidth(
    {int? itemIndex, FinDoc? item, BuildContext? context}) {
  if (isPhone(context))
    return [10, 62, 35];
  else
    return [5, 9, 29, 10, 19, 04, 20];
}

// row height
double getRowHeight({BuildContext? context}) {
  return isPhone(context) ? 65 : 20;
}

// general settings
var padding = SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

// fields content, using strings index not required
// widgets also allowed, then index is used for the key on the widgets
List<dynamic> getItemFieldContent(FinDoc finDoc,
    {int? itemIndex, BuildContext? context}) {
  String classificationId = context!.read<String>();
  if (isPhone(context))
    return [
      CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          finDoc.pseudoId == null ? '' : finDoc.pseudoId!.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(finDoc.pseudoId ?? '', key: Key('id$itemIndex')),
            SizedBox(width: 10),
            Text(classificationId == 'AppHotel'
                ? finDoc.items[0].rentalFromDate != null
                    ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
                    : '???'
                : "${finDoc.creationDate?.toString().substring(0, 11)}"),
          ],
        ),
        Text(finDoc.otherCompany?.name.truncate(25) ?? '',
            key: Key("otherUser$itemIndex")),
        Row(
          children: [
            Text(
                finDoc.status != null
                    ? finDoc.displayStatus(classificationId)!
                    : '??',
                key: Key("status$itemIndex")),
            const SizedBox(width: 10),
            if (finDoc.docType != FinDocType.shipment)
              Text(finDoc.grandTotal.currency(),
                  key: Key("grandTotal$itemIndex")),
            if (finDoc.docType != FinDocType.shipment)
              const SizedBox(width: 10),
            Text(finDoc.items.length.toString(),
                key: Key("itemsLength$itemIndex")),
          ],
        )
      ])
    ];
  else
    return [
      Text(finDoc.pseudoId ?? '', key: Key('id$itemIndex')),
      Text(classificationId == 'AppHotel' &&
              finDoc.items[0].rentalFromDate != null
          ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
          : "${finDoc.creationDate?.toString().substring(0, 11)}"),
      Text(finDoc.otherCompany?.name ?? '', key: Key("otherUser$itemIndex")),
      if (finDoc.docType != FinDocType.shipment)
        Text("${finDoc.grandTotal!.currency()}",
            textAlign: TextAlign.right, key: Key("grandTotal$itemIndex")),
      Text(finDoc.displayStatus(classificationId)!,
          key: Key("status$itemIndex")),
      Text(finDoc.otherCompany!.email ?? '             '),
    ];
}

// buttons
List<Widget> getRowActionButtons({
  Bloc<dynamic, dynamic>? bloc,
  BuildContext? context,
  FinDoc? item,
  int? itemIndex,
}) {
  // order from the web better not touch when in prep
  if (item!.docType == FinDocType.order &&
      item.salesChannel == 'Web' &&
      item.status == FinDocStatusVal.inPreparation) return [];
  return [
    // pdf currently just available for invoice and order
    if ((item.docType == FinDocType.order ||
        item.docType == FinDocType.invoice))
      IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.all(0),
        key: Key('print$itemIndex'),
        icon: const Icon(Icons.print),
        tooltip: 'PDF/Print ${item.docType}',
        onPressed: () async {
          await Navigator.pushNamed(context!, '/printer', arguments: item);
        },
      ),
    if ((item.status != FinDocStatusVal.cancelled &&
        item.status != FinDocStatusVal.completed))
      IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.all(0),
          key: Key('delete$itemIndex'),
          icon: const Icon(Icons.delete_forever),
          tooltip: 'remove item',
          onPressed: () async {
            bool? result = await confirmDialog(
                context!, "delete ${item.pseudoId}?", "cannot be undone!");
            if (result == true) {
              bloc!.add(FinDocUpdate(
                  item.copyWith(status: FinDocStatusVal.cancelled)));
            }
          }),
  ];
}
/* need to copy item and related docs information?
List<TableViewCell> getDataTiles(
  BuildContext context,
  FinDoc finDoc,
  int index,
  FinDocBloc finDocBloc,
) {
  bool isPhone = isAPhone(context);

  List<Widget> items(BuildContext context, FinDoc findoc) {
    String r = isPhone ? '\n' : ' '; // return when used on mobile
    List<Widget> finDocItems = [];
    if (finDoc.docType == FinDocType.payment) {
      finDocItems = [
        ListTile(
            leading: const SizedBox(width: 50),
            title: Text(
                "Type: ${finDoc.items[0].itemType?.itemTypeName ?? '??'}$r"
                "Overr.GlAccount: ${finDoc.items[0].glAccount?.accountCode ?? ''}"))
      ];
    } else {
      finDocItems = List.from(finDoc.items.mapIndexed((index, e) =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            const SizedBox(width: 50),
            ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  maxRadius: 10,
                  child: Text(e.itemSeqId.toString()),
                ),
                title: Text(
                    // blank required before and after productId for automated test
                    finDoc.docType == FinDocType.shipment
                        ? "Product: ${e.description}[${e.productId}] "
                            "Quantity: ${e.quantity.toString()} "
                        : finDoc.docType == FinDocType.order ||
                                finDoc.docType == FinDocType.invoice &&
                                    e.quantity != null
                            ? "ProductId: ${e.productId} $r${e.description}$r"
                                "Quantity: ${e.quantity.toString()} "
                                "Price: ${e.price.toString()} "
                                "SubTotal: ${(e.quantity! * e.price!).toString()}$r"
                                "${e.rentalFromDate == null ? '' : " "
                                    "Rental: ${e.rentalFromDate.toString().substring(0, 10)}/"
                                    "${e.rentalThruDate.toString().substring(0, 10)}"}\n"
                                "${finDoc.docType == FinDocType.invoice ? 'Overr.GLAccount: ${e.glAccount?.accountCode ?? ''}' : ''}$r"
                                "${finDoc.docType == FinDocType.invoice || finDoc.docType == FinDocType.order ? 'ItemType: ${e.itemType!.itemTypeName}' : ''}\n"
                            : '', // payment: no items
                    key: Key('itemLine$index')))
          ])));
    }
    if (finDoc.address != null) {
      finDocItems.add(ListTile(
          leading: const SizedBox(width: 50),
          title: Text("Shipping method: ${finDoc.shipmentMethod} "
              "telephone: ${finDoc.telephoneNr}\n"
              "${findoc.address!.address1} ${findoc.address!.address2} "
              "${findoc.address!.province}\n"
              "${findoc.address!.postalCode} ${finDoc.address!.city}\n"
              "${finDoc.address!.country}")));
    }

    Widget refDocDialog(String id, FinDocType type, bool sales) {
      return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("${type.toString()} Id: "),
            TextButton(
              onPressed: () => showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) => type == FinDocType.payment
                      ? ShowPaymentDialog(
                          FinDoc(paymentId: id, sales: sales, docType: type))
                      : FinDocDialog(type == FinDocType.invoice
                          ? FinDoc(invoiceId: id, sales: sales, docType: type)
                          : type == FinDocType.shipment
                              ? FinDoc(
                                  shipmentId: id, sales: sales, docType: type)
                              : type == FinDocType.order
                                  ? FinDoc(
                                      orderId: finDoc.pseudoId,
                                      sales: sales,
                                      docType: type)
                                  : FinDoc(
                                      transactionId: id,
                                      sales: sales,
                                      docType: type))),
              child: Text(id),
            )
          ]);
    }

    List<Widget> refDoc = [];
    if (finDoc.docType != FinDocType.invoice && finDoc.invoiceId != null) {
      refDoc.add(
          refDocDialog(finDoc.invoiceId!, FinDocType.invoice, finDoc.sales));
    }
    if (finDoc.docType != FinDocType.order && finDoc.orderId != null) {
      refDoc.add(refDocDialog(finDoc.orderId!, FinDocType.order, finDoc.sales));
    }
    if (finDoc.docType != FinDocType.payment && finDoc.paymentId != null) {
      refDoc.add(
          refDocDialog(finDoc.paymentId!, FinDocType.payment, finDoc.sales));
    }
    if (finDoc.docType != FinDocType.shipment && finDoc.shipmentId != null) {
      refDoc.add(
          refDocDialog(finDoc.shipmentId!, FinDocType.shipment, finDoc.sales));
    }
    if (finDoc.docType != FinDocType.transaction &&
        finDoc.transactionId != null) {
      refDoc.add(refDocDialog(
          finDoc.transactionId!, FinDocType.transaction, finDoc.sales));
    }

    if (refDoc.isNotEmpty) {
      finDocItems.add(ListTile(
          leading: const SizedBox(width: 50),
          title: const Text("Referenced Documents:"),
          subtitle: Wrap(children: refDoc)));
    }

    return finDocItems;
  }

  return [];

}
*/