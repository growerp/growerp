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

import '../findoc.dart';

class FinDocListItemTrans extends StatelessWidget {
  const FinDocListItemTrans({
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
    DateTime date = finDoc.placedDate ?? finDoc.creationDate ?? DateTime.now();
    return ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(finDoc.otherUser?.company?.name == null
              ? ''
              : finDoc.otherUser!.company!.name![0]),
        ),
        title: Row(children: <Widget>[
          Expanded(child: Text(finDoc.id() ?? '?', key: Key('id$index'))),
          Expanded(
              child: Text(finDoc.description.truncate(isPhone ? 15 : 40),
                  key: Key('descr$index'))),
          if (!isPhone) const SizedBox(width: 10),
          if (!isPhone)
            Expanded(
                child: Text(date.toString().substring(0, 10),
                    key: Key('date$index'))),
          if (!isPhone) const SizedBox(width: 10),
          if (!isPhone)
            Expanded(
                child: Text(
              finDoc.isPosted == true ? 'Y' : 'N',
              key: Key("status$index"),
              textAlign: TextAlign.center,
            )),
          if (!isPhone) const SizedBox(width: 10),
          if (!isPhone)
            Expanded(
                child:
                    Text(finDoc.invoiceId ?? '', textAlign: TextAlign.center)),
          if (!isPhone) const SizedBox(width: 10),
          if (!isPhone)
            Expanded(
                child:
                    Text(finDoc.paymentId ?? '', textAlign: TextAlign.center)),
          if (!isPhone) const SizedBox(width: 10),
          if (!isPhone)
            Expanded(
                child: Text(finDoc.grandTotal.toString(),
                    textAlign: TextAlign.center)),
          if (!isPhone) const SizedBox(width: 10),
          if (!isPhone)
            Expanded(
                child: Text(finDoc.items.length.toString(),
                    textAlign: TextAlign.center)),
        ]),
        subtitle: isPhone
            ? Row(children: <Widget>[
                Expanded(child: Text(date.toString().substring(0, 10))),
                Expanded(
                    child: Text(finDoc.grandTotal.toString(),
                        key: Key("grandTotal$index"))),
                Text(finDoc.status == FinDocStatusVal.completed ? 'Y' : 'N',
                    key: Key("status$index")),
              ])
            : null,
        trailing: SizedBox(
            width: isPhone ? 96 : 195,
            child: itemButtons(context, paymentMethod, finDocBloc, repos)),
        children: items(finDoc));
  }

  Widget itemButtons(BuildContext context, PaymentMethod? paymentMethod,
      FinDocBloc finDocBloc, FinDocAPIRepository repos) {
    return Row(children: [
      if (finDoc.isPosted == false)
        IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          tooltip: 'Cancel ${finDoc.docType}',
          onPressed: () {
            finDocBloc.add(FinDocUpdate(
                finDoc.copyWith(status: FinDocStatusVal.cancelled)));
          },
        ),
      if (!isPhone && finDoc.isPosted == false)
        TextButton(
            key: Key('nextStatus$index'),
            onPressed: () {
              finDocBloc.add(FinDocUpdate(finDoc.copyWith(isPosted: true)));
            },
            child: const Text('Post')),
      if (finDoc.isPosted == null || finDoc.isPosted == false)
        IconButton(
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
                          child: FinDocDialog(finDoc: finDoc)));
                });
          },
        ),
    ]);
  }

  List<Widget> items(FinDoc findoc) {
    List<Widget> finDocItems = List.from(finDoc.items.mapIndexed((index, e) {
      String debitCredit = '';
      if (e.isDebit != null && e.isDebit == true) {
        debitCredit = 'Debit';
      } else {
        debitCredit = 'Credit';
      }
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        const SizedBox(width: 50),
        if (findoc.journal != null)
          Expanded(child: Text("JournalId: ${finDoc.journal}")),
        Expanded(
            child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  maxRadius: 10,
                  child: Text(e.itemSeqId.toString()),
                ),
                title: Text(
                    "GlAccount: ${e.glAccount?.accountCode} ${e.glAccount?.accountName}  "
                    "${isPhone ? '\n' : ''}"
                    "Amount: $debitCredit ${e.price}",
                    key: Key('itemLine$index'))))
      ]);
    }));
    return finDocItems;
  }
}