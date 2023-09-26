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
import 'package:growerp_models/growerp_models.dart';

import '../findoc.dart';

class FinDocListHeaderTrans extends StatefulWidget {
  const FinDocListHeaderTrans({
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
  State<FinDocListHeaderTrans> createState() => _FinDocListHeaderTransState();
}

class _FinDocListHeaderTransState extends State<FinDocListHeaderTrans> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    List<Widget> fields = [
      const Text("Trans.Id"),
      const Expanded(child: SizedBox(width: 10)),
      const Text("Descr.")
    ];
    if (!widget.isPhone) {
      fields.addAll([
        const Expanded(child: SizedBox(width: 10)),
        const Text("Date"),
        const Expanded(child: SizedBox(width: 10)),
        const Text("Posted?"),
        const Expanded(child: SizedBox(width: 10)),
        const Text("Invoice"),
        const Expanded(child: SizedBox(width: 10)),
        const Text("Payment"),
        const Expanded(child: SizedBox(width: 10)),
        const Text("Total"),
        const Expanded(child: SizedBox(width: 10)),
        const Expanded(child: Text("#")),
      ]);
    }

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
            : Row(children: fields),
        subtitle: widget.isPhone
            ? const Row(children: <Widget>[
                Expanded(child: Text("Date")),
                Expanded(child: Text("Total")),
                Expanded(child: Text("Posted?")),
                Divider(),
              ])
            : null,
        trailing: SizedBox(width: widget.isPhone ? 40 : 195));
  }
}
