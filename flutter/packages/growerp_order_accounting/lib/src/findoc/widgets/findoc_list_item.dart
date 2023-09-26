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
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';

import '../findoc.dart';

class FinDocListItem extends StatelessWidget {
  const FinDocListItem({
    Key? key,
    required this.finDoc,
    required this.index,
    required this.sales,
    required this.docType,
    required this.isPhone,
    required this.onlyRental,
    this.additionalItemButton,
    this.paymentMethod,
  }) : super(key: key);

  final FinDoc finDoc;
  final int index;
  final bool sales;
  final FinDocType docType;
  final bool isPhone;
  final bool onlyRental;
  final Widget? additionalItemButton;
  final PaymentMethod? paymentMethod;

  @override
  Widget build(BuildContext context) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    FinDocAPIRepository repos = context.read<FinDocAPIRepository>();
    String classificationId = GlobalConfiguration().get("classificationId");
    List<Widget> titleFields = [];
    if (isPhone) {
      titleFields = [
        Text(finDoc.id() ?? '', key: Key('id$index')),
        const Expanded(child: SizedBox(width: 10)),
        Text(classificationId == 'AppHotel'
            ? finDoc.items[0].rentalFromDate != null
                ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
                : '???'
            : "${finDoc.creationDate?.toString().substring(0, 11)}"),
      ];
    } else {
      titleFields = [
        Text(finDoc.id() ?? '', key: Key('id$index')),
        const Expanded(child: SizedBox(width: 10)),
        Text(classificationId == 'AppHotel' &&
                finDoc.items[0].rentalFromDate != null
            ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
            : "${finDoc.creationDate?.toString().substring(0, 11)}"),
        const Expanded(child: SizedBox(width: 10)),
        Text(finDoc.otherCompany?.name ?? '', key: Key("otherUser$index")),
        const Expanded(child: SizedBox(width: 10)),
        Text(finDoc.grandTotal.toString(), key: Key("grandTotal$index")),
        const Expanded(child: SizedBox(width: 10)),
        Text(finDoc.displayStatus(classificationId)!, key: Key("status$index")),
        const Expanded(child: SizedBox(width: 10)),
        Text(finDoc.otherCompany!.email ?? ''),
      ];
    }

    List<Widget> subTitleFields = [];
    if (isPhone) {
      subTitleFields = [
        Column(
          children: [
            Text(finDoc.otherUser?.company!.name ?? '',
                key: Key("otherUser$index")),
            Row(
              children: [
                Text(
                    finDoc.status != null
                        ? finDoc.displayStatus(classificationId)!
                        : '??',
                    key: Key("status$index")),
                const SizedBox(width: 10),
                Text(
                    finDoc.grandTotal != null
                        ? finDoc.grandTotal.toString()
                        : '',
                    key: Key("grandTotal$index")),
                const SizedBox(width: 10),
                Text(finDoc.items.length.toString(),
                    key: Key("itemsLength$index")),
              ],
            )
          ],
        ),
      ];
    } else {
      subTitleFields = [];
    }

    List<Widget> fields = [
      Text(finDoc.id() ?? '', key: Key('id$index')),
      const Expanded(child: SizedBox(width: 10)),
      const Expanded(child: SizedBox(width: 10)),
      Text(finDoc.items.length.toString()),
    ];
    if (!isPhone) {
      fields.addAll([
        const Expanded(child: SizedBox(width: 10)),
        Text(classificationId == 'AppHotel' &&
                finDoc.items[0].rentalFromDate != null
            ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
            : "${finDoc.creationDate?.toString().substring(0, 11)}"),
        const Expanded(child: SizedBox(width: 10)),
        Text("${finDoc.grandTotal}", key: Key("grandTotal$index")),
        const Expanded(child: SizedBox(width: 10)),
        Text("${finDoc.displayStatus(classificationId)}",
            key: Key("status$index")),
        const Expanded(child: SizedBox(width: 10)),
        Text(
          finDoc.otherUser!.email ?? '??',
          key: Key('email$index'),
        ),
        const Divider(),
      ]);
    }

    return ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(finDoc.otherUser?.company?.name == null
              ? ''
              : finDoc.otherUser!.company!.name![0]),
        ),
        title: Row(children: titleFields),
        subtitle: Row(children: subTitleFields),
        trailing: SizedBox(
          width: isPhone ? 70 : 195,
          child: docType == FinDocType.shipment
              ? (sales
                  ? IconButton(
                      key: Key('nextStatus$index'),
                      icon: const Icon(Icons.send),
                      tooltip:
                          FinDocStatusVal.nextStatus(finDoc.status!).toString(),
                      onPressed: () {
                        finDocBloc.add(FinDocUpdate(finDoc.copyWith(
                            status:
                                FinDocStatusVal.nextStatus(finDoc.status!))));
                      })
                  : IconButton(
                      key: Key('nextStatus$index'),
                      icon: const Icon(Icons.call_received),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return RepositoryProvider.value(
                                  value: repos,
                                  child: BlocProvider.value(
                                      value: finDocBloc,
                                      child: ShipmentReceiveDialog(finDoc)));
                            });
                      }))
              : classificationId == 'AppHotel' &&
                      finDoc.status == FinDocStatusVal.approved
                  ? IconButton(
                      key: Key('nextStatus$index'),
                      icon: const Icon(Icons.check_box_sharp),
                      tooltip:
                          FinDocStatusVal.nextStatus(finDoc.status!).toString(),
                      onPressed: () {
                        finDocBloc.add(FinDocUpdate(finDoc.copyWith(
                            status:
                                FinDocStatusVal.nextStatus(finDoc.status!))));
                      })
                  : finDoc.status != null &&
                          FinDocStatusVal.statusFixed(finDoc.status!) == false
                      ? itemButtons(context, paymentMethod, finDocBloc, repos)
                      : finDoc.sales == true &&
                              finDoc.status == FinDocStatusVal.approved
                          ? additionalItemButton
                          : null,
        ),
        children: items(context, finDoc));
  }

  Widget? itemButtons(BuildContext context, PaymentMethod? paymentMethod,
      FinDocBloc finDocBloc, FinDocAPIRepository repos) {
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
            finDoc.docType == FinDocType.order &&
            finDoc.docType == FinDocType.invoice)
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
        SizedBox(
          width: 30,
          child: IconButton(
            icon: const Icon(Icons.edit),
            key: Key('edit$index'),
            tooltip: 'Edit ${finDoc.docType}',
            onPressed: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return RepositoryProvider.value(
                        value: repos,
                        child: BlocProvider.value(
                            value: finDocBloc,
                            child: onlyRental == true
                                ? ReservationDialog(
                                    finDoc: finDoc, original: finDoc)
                                : finDoc.docType == FinDocType.payment
                                    ? PaymentDialog(
                                        finDoc: finDoc,
                                        paymentMethod: paymentMethod,
                                      )
                                    : FinDocDialog(finDoc: finDoc)));
                  });
            },
          ),
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
                "Type: ${finDoc.items[0].itemType?.itemTypeName ?? '??'}[${finDoc.items[0].itemType?.accountCode ?? '??'}]$r"
                "Overr.GlAccount: ${finDoc.items[0].glAccount?.accountCode ?? ''}"))
      ];
    } else {
      finDocItems = List.from(finDoc.items.mapIndexed((index, e) =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            const SizedBox(width: 50),
            Expanded(
                child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      maxRadius: 10,
                      child: Text(e.itemSeqId.toString()),
                    ),
                    title: Text(
                        // blank required before and after productId for automated test
                        finDoc.docType == FinDocType.shipment
                            ? "ProductId: ${e.productId} "
                                "Quantity: ${e.quantity.toString()} "
                            : finDoc.docType == FinDocType.order ||
                                    finDoc.docType == FinDocType.invoice
                                ? "ProductId: ${e.productId} $r${e.description}$r"
                                    "Quantity: ${e.quantity.toString()} "
                                    "Price: ${e.price.toString()}$r"
                                    "SubTotal: ${(e.quantity! * e.price!).toString()}$r${e.rentalFromDate == null ? '' : " "
                                        "Rental: ${e.rentalFromDate.toString().substring(0, 10)}/"
                                        "${e.rentalThruDate.toString().substring(0, 10)}"}\n"
                                    "${finDoc.docType == FinDocType.invoice ? 'Overr.GLAccount: ${e.glAccount?.accountCode ?? ''}' : ''}$r"
                                    "${finDoc.docType == FinDocType.invoice || finDoc.docType == FinDocType.order ? 'ItemType: ${e.itemType!.itemTypeName}[${e.itemType!.accountCode}]' : ''}\n"
                                : '', // payment: no items
                        key: Key('itemLine$index'))))
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
              onPressed: () async => await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) => type == FinDocType.payment
                      ? ShowPaymentDialog(
                          FinDoc(paymentId: id, sales: sales, docType: type))
                      : ShowFinDocDialog(type == FinDocType.invoice
                          ? FinDoc(invoiceId: id, sales: sales, docType: type)
                          : type == FinDocType.shipment
                              ? FinDoc(
                                  shipmentId: id, sales: sales, docType: type)
                              : type == FinDocType.order
                                  ? FinDoc(
                                      orderId: id, sales: sales, docType: type)
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
}
