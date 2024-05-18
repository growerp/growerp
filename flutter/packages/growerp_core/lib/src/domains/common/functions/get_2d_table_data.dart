import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// a program to generate the structure for the TableView,builder 2d scrollable
/// data tables
(List<List<TableViewCell>>, List<double>, double? height) get2dTableData<T>(
  // a list is strings or widgets used as column headers
  List<dynamic> Function({int? itemIndex, T? item, BuildContext? context})
      getItemFieldNames,
  // the width of the columns in percetage of the screen width.
  List<double> Function({int? itemIndex, T? item, BuildContext? context})
      getItemFieldWidth,
  // a list a classes containing the column fields
  List<T> items,
  // get the content fields/widgets of a single item from the items list
  List<dynamic> Function(T, {int? itemIndex, BuildContext? context})
      getItemFieldContent,
  // this is an optional extra field,
  // used to forward to the functions above if required
  {
  // get the item row height
  double Function({BuildContext? context})? getRowHeight,
  // get a list of iconbuttons  for processing a single row.
  List<Widget> Function({int? itemIndex, T? item, BuildContext? context})?
      getRowActionButtons,
  BuildContext? context,
  // the heigth of the row
}) {
  List<List<TableViewCell>> tableViewCells = []; // table content
  List<TableViewCell> contentRow = []; // row content
  // create table content
  late List<dynamic> names;
  for (final (itemIndex, item) in items.indexed) {
    if (itemIndex == 0) {
      // create column headers
      names = getItemFieldNames(
        itemIndex: itemIndex,
        context: context,
        item: item,
      );
      for (final name in names) {
        contentRow.add(
            TableViewCell(child: name is String ? Text(name) : name as Widget));
      }
      tableViewCells.add(contentRow);
      contentRow = [];
    }
    // add data to table
    List<dynamic> fields =
        getItemFieldContent(item, itemIndex: itemIndex, context: context);
    for (final (fieldIndex, field) in fields.indexed) {
      // add boilerplate code and key (for testing) to fields
      contentRow.add(TableViewCell(
          child: field is String
              ? Text(field, key: Key('${names[fieldIndex]}$itemIndex'))
              : field as Widget));
    }
    // get the buttons
    if (getRowActionButtons != null) {
      contentRow.add(TableViewCell(
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: getRowActionButtons(
                  itemIndex: itemIndex, item: item, context: context))));

      // add to table
      tableViewCells.add(contentRow);
      contentRow = [];
    }
  }
  // calculate the single field with in percetage of the screen width
  double width = MediaQuery.of(context!).size.width;
  List<double> perc = getItemFieldWidth(context: context);
  List<double> result = [];
  for (final p in perc) {
    result.add(width / 100 * p);
  }
  // provide row height if requested
  double? height = 40;
  if (getRowHeight != null) {
    height = getRowHeight(context: context);
  }
  return (tableViewCells, result, height);
}
