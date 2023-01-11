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
import 'package:global_configuration/global_configuration.dart';
import '../findoc.dart';

class FinDocListHeader extends StatefulWidget {
  const FinDocListHeader({
    Key? key,
    required this.sales,
    required this.docType,
    required this.isPhone,
    required this.finDocBloc,
  }) : super(key: key);
  final bool sales;
  final FinDocType docType;
  final bool isPhone;
  final FinDocBloc finDocBloc;

  @override
  State<FinDocListHeader> createState() => _FinDocListHeaderState();
}

class _FinDocListHeaderState extends State<FinDocListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    String classificationId = GlobalConfiguration().get("classificationId");
    return Material(
        child: ListTile(
            leading: GestureDetector(
                key: Key('search'),
                onTap: (() =>
                    setState(() => search ? search = false : search = true)),
                child: Image.asset(
                  'assets/images/search.png',
                  height: 30,
                )),
            title: search
                ? Row(children: <Widget>[
                    Expanded(
                        child: TextField(
                      key: Key('searchField'),
                      autofocus: true,
                      decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          hintText: 'search with ID'),
                      onChanged: ((value) => setState(() {
                            searchString = value;
                          })),
                    )),
                    ElevatedButton(
                        key: Key('searchButton'),
                        child: Text('search'),
                        onPressed: () {
                          widget.finDocBloc
                              .add(FinDocFetch(searchString: searchString));
                        })
                  ])
                : Row(children: <Widget>[
                    SizedBox(width: 80, child: Text(widget.docType.toString())),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text((widget.sales ? "Customer" : "Supplier") +
                            ' name & Company')),
                    if (!widget.isPhone && widget.docType != FinDocType.payment)
                      SizedBox(
                          width: 80,
                          child: Text("#items", textAlign: TextAlign.left)),
                  ]),
            subtitle: Row(children: <Widget>[
              SizedBox(
                  width: 80,
                  child: Text(classificationId == 'AppHotel'
                      ? 'Reserv. Date'
                      : 'Creation Date')),
              SizedBox(width: 76, child: Text("Total")),
              SizedBox(width: 90, child: Text("Status")),
              if (!widget.isPhone) Expanded(child: Text("Email Address")),
              if (!widget.isPhone)
                Expanded(child: Text("${widget.docType} description")),
            ]),
            trailing: SizedBox(width: widget.isPhone ? 40 : 195)));
  }
}
