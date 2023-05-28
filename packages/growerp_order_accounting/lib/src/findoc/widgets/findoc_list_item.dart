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
import 'package:growerp_core/growerp_core.dart';
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

    return ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(finDoc.otherUser?.company?.name == null
              ? ''
              : finDoc.otherUser!.company!.name![0]),
        ),
        title: Row(
          children: <Widget>[
            Expanded(child: Text("${finDoc.id()}", key: Key('id$index'))),
            Expanded(
                child: Text(
                    "${finDoc.otherUser?.firstName ?? ''} "
                    "${finDoc.otherUser?.lastName ?? ''}${isPhone ? '\n' : ' '}"
                    "${finDoc.otherUser?.company!.name ?? ''}",
                    key: Key("otherUser$index"))),
            if (!isPhone && docType != FinDocType.payment)
              SizedBox(width: 80, child: Text("${finDoc.items.length}")),
          ],
        ),
        subtitle: Row(children: <Widget>[
          if (!isPhone)
            Expanded(
                child: Text(classificationId == 'AppHotel'
                    ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
                    : "${finDoc.creationDate?.toString().substring(0, 11)}")),
          Expanded(
              child:
                  Text("${finDoc.grandTotal}", key: Key("grandTotal$index"))),
          Expanded(
              child: Text("${finDoc.displayName(classificationId)}",
                  key: Key("status$index"))),
          if (!isPhone)
            Expanded(
                child: Text(
              finDoc.otherUser!.email ?? '??',
              key: Key('email$index'),
            )),
          if (!isPhone)
            Expanded(
                child: Text(
              finDoc.description ?? '',
              key: Key('description$index'),
            )),
        ]),
        trailing: SizedBox(
          width: isPhone ? 100 : 195,
          child: docType == FinDocType.payment &&
                  finDoc.status == FinDocStatusVal.approved
              ? TextButton(
                  key: Key('nextStatus$index'),
                  onPressed: () {
                    finDocBloc.add(FinDocConfirmPayment(finDoc));
                  },
                  child: const Text(
                    "Set to 'Paid'",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : docType == FinDocType.shipment
                  ? (sales
                      ? IconButton(
                          key: Key('nextStatus$index'),
                          icon: const Icon(Icons.send),
                          tooltip: FinDocStatusVal.nextStatus(finDoc.status!)
                              .toString(),
                          onPressed: () {
                            finDocBloc.add(FinDocUpdate(finDoc.copyWith(
                                status: FinDocStatusVal.nextStatus(
                                    finDoc.status!))));
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
                                          child:
                                              ShipmentReceiveDialog(finDoc)));
                                });
                          }))
                  : classificationId == 'AppHotel' &&
                          finDoc.status == FinDocStatusVal.approved
                      ? IconButton(
                          key: Key('nextStatus$index'),
                          icon: const Icon(Icons.check_box_sharp),
                          tooltip: FinDocStatusVal.nextStatus(finDoc.status!)
                              .toString(),
                          onPressed: () {
                            finDocBloc.add(FinDocUpdate(finDoc.copyWith(
                                status: FinDocStatusVal.nextStatus(
                                    finDoc.status!))));
                          })
                      : finDoc.status != null &&
                              FinDocStatusVal.statusFixed(finDoc.status!) ==
                                  false
                          ? itemButtons(
                              context, paymentMethod, finDocBloc, repos)
                          : finDoc.sales == true &&
                                  finDoc.status == FinDocStatusVal.approved
                              ? additionalItemButton
                              : null,
        ),
        children: items(finDoc));
  }

  Widget? itemButtons(BuildContext context, PaymentMethod? paymentMethod,
      FinDocBloc finDocBloc, FinDocAPIRepository repos) {
    if (finDoc.salesChannel != 'Web' ||
        (finDoc.salesChannel == 'Web' &&
            finDoc.status != FinDocStatusVal.inPreparation)) {
      return Row(children: [
        Visibility(
            visible: !isPhone,
            child: Row(children: [
              IconButton(
                key: Key('delete$index'),
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Cancel ${finDoc.docType}',
                onPressed: () {
                  finDocBloc.add(FinDocUpdate(
                      finDoc.copyWith(status: FinDocStatusVal.cancelled)));
                },
              ),
              IconButton(
                key: Key('print$index'),
                icon: const Icon(Icons.print),
                tooltip: 'PDF/Print ${finDoc.docType}',
                onPressed: () async {
                  await Navigator.pushNamed(context, '/printer',
                      arguments: finDoc);
                },
              ),
            ])),
        IconButton(
            key: Key('nextStatus$index'),
            icon: const Icon(Icons.arrow_upward),
            tooltip: finDoc.status != null
                ? FinDocStatusVal.nextStatus(finDoc.status!).toString()
                : '',
            onPressed: () {
              finDocBloc.add(FinDocUpdate(finDoc.copyWith(
                  status: FinDocStatusVal.nextStatus(finDoc.status!))));
            }),
        Visibility(
            visible: [
              FinDocType.order,
              FinDocType.invoice,
              FinDocType.payment,
            ].contains(finDoc.docType),
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
            )),
      ]);
    }
    return null;
  }

  List<Widget> items(FinDoc findoc) {
    List<Widget> finDocItems = List.from(finDoc.items.mapIndexed((index, e) =>
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
                      finDoc.docType == FinDocType.order ||
                              finDoc.docType == FinDocType.invoice
                          ? "ProductId: ${e.productId} Description: ${e.description} Quantity: ${e.quantity.toString()} Price: ${e.price.toString()} SubTotal: ${(e.quantity! * e.price!).toString()}${e.rentalFromDate == null ? '' : " Rental: ${e.rentalFromDate.toString().substring(0, 10)} "
                              "${e.rentalThruDate.toString().substring(0, 10)}"}"
                          : finDoc.docType == FinDocType.transaction
                              ? "Type: ${e.itemType?.itemTypeId.substring(3)}\n"
                                  "GlAccount: ${e.glAccount?.accountCode} ${e.glAccount?.accountName}\n"
                                  "Amount: ${e.price} "
                              : finDoc.docType == FinDocType.shipment
                                  ? "ProductId: ${e.productId} "
                                      "Quantity: ${e.quantity.toString()} "
                                  : '', // payment
                      key: Key('itemLine$index'))))
        ])));
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

    return finDocItems;
  }
}
