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
// original article:
// https://www.kindacode.com/article/flutter-making-a-dropdown-multiselect-with-checkboxes/
import 'package:flutter/material.dart';
import 'popup_dialog_no_scaf.dart';

class MultiSelect<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> selectedItems;
  const MultiSelect(
      {Key? key,
      this.title = 'Please select one or more',
      required this.items,
      this.selectedItems = const []})
      : super(key: key);

  @override
  MultiSelectState createState() => MultiSelectState<T>();
}

class MultiSelectState<T> extends State<MultiSelect> {
  late List<T> selectedItems;
  String message = '';

// This function is triggered when a checkbox is checked or unchecked
  void _itemChange(itemValue, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedItems.add(itemValue);
      } else {
        selectedItems.remove(itemValue);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    selectedItems = List.of(widget.selectedItems as List<T>);
  }

  @override
  Widget build(BuildContext context) {
    return popUpDialogNoScaffold(
      key: const Key('multiSelect'),
      width: 350,
      context: context,
      title: widget.title,
      children: [
        widget.items.isEmpty
            ? const Center(
                child: Text('nothing found, add some?',
                    style: TextStyle(color: Colors.red)))
            : ListBody(
                children: widget.items
                    .map((item) => CheckboxListTile(
                          value: selectedItems.contains(item),
                          title: Text(item.toString()),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (isChecked) =>
                              _itemChange(item, isChecked!),
                        ))
                    .toList(),
              ),
        Row(children: [
          Expanded(
              child: ElevatedButton(
            key: const Key('ok'),
            onPressed: (() {
              return Navigator.pop(context, selectedItems);
            }),
            child: const Text('OK'),
          ))
        ]),
      ],
    );
  }
}
