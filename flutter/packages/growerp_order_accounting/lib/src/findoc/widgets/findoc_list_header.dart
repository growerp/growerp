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
import 'package:growerp_models/growerp_models.dart';
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
    List<Widget> titleFields = [];
    if (widget.isPhone) {
      titleFields = [
        Text('${widget.docType} Id'),
        const Expanded(child: SizedBox(width: 10)),
        Text(classificationId == 'AppHotel' ? 'Reserv. Date' : 'Creation Date'),
        const Expanded(child: SizedBox(width: 10)),
      ];
    } else {
      titleFields = [
        Text('${widget.docType} Id'),
        const Expanded(child: SizedBox(width: 10)),
        Text(classificationId == 'AppHotel' ? 'Reserv. Date' : 'Creation Date'),
        const Expanded(child: SizedBox(width: 30)),
        Text(widget.sales ? 'Customer' : 'Supplier'),
        const Expanded(child: SizedBox(width: 30)),
        const Text("Total"),
        const Expanded(child: SizedBox(width: 30)),
        const Text("Status"),
        const Expanded(child: SizedBox(width: 30)),
        const Text("Email Address"),
      ];
    }

    List<Widget> subTitleFields = [];
    widget.isPhone
        ? subTitleFields = [
            Column(
              children: [
                Text(widget.sales ? 'Customer' : 'Supplier'),
                const Row(
                  children: [
                    Text('Status'),
                    SizedBox(width: 10),
                    Text('Total'),
                    SizedBox(width: 10),
                    Text('#Items'),
                  ],
                ),
              ],
            ),
          ]
        : subTitleFields = [];

    return ListTile(
        leading: GestureDetector(
            key: const Key('search'),
            onTap: (() =>
                setState(() => search ? search = false : search = true)),
            child: const Icon(Icons.search_sharp, size: 40)),
        title: search
            ? Row(children: <Widget>[
                Expanded(
                    child: TextField(
                  key: const Key('searchField'),
                  autofocus: true,
                  decoration: const InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      hintText: 'search with ID'),
                  onChanged: ((value) => setState(() {
                        searchString = value;
                      })),
                )),
                ElevatedButton(
                    key: const Key('searchButton'),
                    child: const Text('search'),
                    onPressed: () {
                      widget.finDocBloc
                          .add(FinDocFetch(searchString: searchString));
                    })
              ])
            : Row(children: titleFields),
        subtitle: Row(children: subTitleFields),
        trailing: SizedBox(width: widget.isPhone ? 40 : 195));
  }
}
