/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// original article:
// https://www.kindacode.com/article/flutter-making-a-dropdown-multiselect-with-checkboxes/
import 'package:flutter/material.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';
import 'popup_dialog_no_scaf.dart';

class MultiSelect<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> selectedItems;
  const MultiSelect({
    super.key,
    this.title = 'Please select one or more',
    required this.items,
    this.selectedItems = const [],
  });

  @override
  MultiSelectState createState() => MultiSelectState<T>();
}

class MultiSelectState<T> extends State<MultiSelect> {
  late List<T> selectedItems;
  String message = '';
  CoreLocalizations? _localizations;

  // This function is triggered when a checkbox is checked or unchecked
  void _itemChange(dynamic itemValue, bool isSelected) {
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
    _localizations = CoreLocalizations.of(context);
    return popUpDialogNoScaffold(
      key: const Key('multiSelect'),
      width: 350,
      context: context,
      title: widget.title,
      children: [
        widget.items.isEmpty
            ? const Center(
                child: Text(
                  'nothing found, add some?',
                  style: TextStyle(color: Colors.red),
                ),
              )
            : ListBody(
                children: widget.items
                    .map(
                      (item) => CheckboxListTile(
                        value: selectedItems.contains(item),
                        title: Text(item.toString()),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (isChecked) => _itemChange(item, isChecked!),
                      ),
                    )
                    .toList(),
              ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('ok'),
                onPressed: (() {
                  return Navigator.pop(context, selectedItems);
                }),
                child: Text(_localizations!.ok),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
