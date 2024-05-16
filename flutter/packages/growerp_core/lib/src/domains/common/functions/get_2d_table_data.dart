import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// a program to generate the structure for the TableView,builder 2d scrollable
/// data tables
List<List<TableViewCell>> get2dTableData<T>(
  // a list is strings used as column headers
  List<String> Function(
          {String? classificationId, FinDocType? docType, bool? sales})
      getNames,
  // the width of the columns
  List<double> lengths,
  // a list a classes containing the column fields
  List<T> items,
  // get the content fields/widgets of a single item from the items list
  List<dynamic> Function(T,
          {int? index,
          String? classificationId,
          FinDocType? docType,
          bool? sales})
      getItemsContent,
  // get a list of iconbuttons for processing a single row.
  List<Widget> Function(int) getButtons,
) {
  List<List<TableViewCell>> tableViewCells = []; // table content
  List<TableViewCell> contentRow = []; // row content
  // create table content
  List<String> names = getNames();
  for (final (itemIndex, item) in items.indexed) {
    if (itemIndex == 0) {
      // create column headers
      for (final name in names) {
        contentRow.add(TableViewCell(child: Text(name)));
      }
      tableViewCells.add(contentRow);
      contentRow = [];
    }
    // add data to table
    List<dynamic> fields = getItemsContent(item, index: itemIndex);
    for (final (fieldIndex, field) in fields.indexed) {
      // add boilerplate code and key (for testing) to fields
      contentRow.add(TableViewCell(
          child: field is String
              ? Text(field, key: Key('${names[fieldIndex]}$itemIndex'))
              : field as Widget));
    }
    // get the buttons
    var buttons = getButtons(itemIndex);
    for (final button in buttons) {
      contentRow.add(TableViewCell(child: button));
    }
    // add to table
    tableViewCells.add(contentRow);
    contentRow = [];
  }
  return tableViewCells;
}
