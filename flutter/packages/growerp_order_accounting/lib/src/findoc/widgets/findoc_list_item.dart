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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../../growerp_order_accounting.dart';

List<TableViewCell> getDataTiles(
  BuildContext context,
  FinDoc finDoc,
  int index,
  FinDocBloc finDocBloc,
) {
  bool isPhone = isAPhone(context);

  /*context
          .read<AuthBloc>()
          .state
          .authenticate
          ?.company!
          .currency!
          .currencyId,
    */
  String classificationId = context.read<String>();
  List<Widget> tableCells = [];
  if (isPhone) {
    tableCells = <Widget>[
      CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          finDoc.pseudoId!.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(finDoc.pseudoId ?? '', key: Key('id$index')),
            SizedBox(width: 10),
            Text(classificationId == 'AppHotel'
                ? finDoc.items[0].rentalFromDate != null
                    ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
                    : '???'
                : "${finDoc.creationDate?.toString().substring(0, 11)}"),
          ],
        ),
        Text(finDoc.otherCompany?.name.truncate(25) ?? '',
            key: Key("otherUser$index")),
        Row(
          children: [
            Text(
                finDoc.status != null
                    ? finDoc.displayStatus(classificationId)!
                    : '??',
                key: Key("status$index")),
            const SizedBox(width: 10),
            if (finDoc.docType != FinDocType.shipment)
              Text(
                  finDoc.grandTotal != null
                      ? "${finDoc.grandTotal!.currency()}"
                      : '',
                  key: Key("grandTotal$index")),
            if (finDoc.docType != FinDocType.shipment)
              const SizedBox(width: 10),
            Text(finDoc.items.length.toString(), key: Key("itemsLength$index")),
          ],
        )
      ]),
    ];
  } else {
    tableCells = <Widget>[
      Text(finDoc.pseudoId ?? '', key: Key('id$index')),
      Text(classificationId == 'AppHotel' &&
              finDoc.items[0].rentalFromDate != null
          ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
          : "${finDoc.creationDate?.toString().substring(0, 11)}"),
      Text(finDoc.otherCompany?.name ?? '', key: Key("otherUser$index")),
      if (finDoc.docType != FinDocType.shipment)
        Text("${finDoc.grandTotal!.currency()}",
            textAlign: TextAlign.right, key: Key("grandTotal$index")),
      Text(finDoc.displayStatus(classificationId)!, key: Key("status$index")),
      Text(finDoc.otherCompany!.email ?? '             '),
    ];
  }

  Widget? itemButtons(BuildContext context, FinDocBloc finDocBloc) {
    if (finDoc.salesChannel != 'Web' ||
        (finDoc.salesChannel == 'Web' &&
            finDoc.status != FinDocStatusVal.inPreparation)) {
      return Row(children: [
        if (!isPhone)
          IconButton(
            key: Key('delete$index'),
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Cancel ${finDoc.docType}',
            onPressed: () {
              finDocBloc.add(FinDocUpdate(
                  finDoc.copyWith(status: FinDocStatusVal.cancelled)));
            },
          ),
        if (!isPhone &&
            (finDoc.docType == FinDocType.order ||
                finDoc.docType == FinDocType.invoice))
          IconButton(
            key: Key('print$index'),
            icon: const Icon(Icons.print),
            tooltip: 'PDF/Print ${finDoc.docType}',
            onPressed: () async {
              await Navigator.pushNamed(context, '/printer', arguments: finDoc);
            },
          ),
        SizedBox(
          width: 30,
          child: IconButton(
              key: Key('nextStatus$index'),
              icon: const Icon(Icons.arrow_upward),
              tooltip: finDoc.status != null
                  ? FinDocStatusVal.nextStatus(finDoc.status!).toString()
                  : '',
              onPressed: () {
                finDocBloc.add(FinDocUpdate(finDoc.copyWith(
                    status: FinDocStatusVal.nextStatus(finDoc.status!))));
              }),
        ),
      ]);
    }
    return null;
  }

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

  List<TableViewCell> tableViewCells = [];
  for (int fieldIndex = 0; fieldIndex < tableCells.length; fieldIndex++) {
    tableViewCells.add(TableViewCell(child: tableCells[fieldIndex]));
  }
  tableViewCells
      .add(TableViewCell(child: itemButtons(context, finDocBloc) ?? Text('')));
  return tableViewCells;
}
