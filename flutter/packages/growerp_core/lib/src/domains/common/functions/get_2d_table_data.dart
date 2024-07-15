import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// a program to generate the structure for the TableView,builder 2d scrollable
/// data tables
// return parameters

/// Table row definition
class TableRowContent {
  final dynamic fieldName; // can be string or widget
  final double fieldWidth;
  final dynamic fieldContent;

  TableRowContent({
    required this.fieldWidth,
    required this.fieldName,
    required this.fieldContent,
  });
}

/// TableView.builder definition
class TableData {
  final double rowHeight;
  final List<TableRowContent> rowContent; // name,width,content,action buttons
  TableData({
    required this.rowHeight,
    required this.rowContent,
  });
}

(List<List<TableViewCell>>, List<double>, double? height) get2dTableData1<T>(
    TableData Function(Bloc bloc, String classificationId, BuildContext context,
            List<T> items)
        getTableData,
    {Bloc? bloc,
    required String classificationId,
    required BuildContext context,
    required List<T> items}) {
  TableData tableData = getTableData(bloc!, '', context, items);

  List<List<TableViewCell>> tableViewCells = []; // table content
  List<TableViewCell> contentRow = []; // row content
  // create table content headers
  for (final rowContent in tableData.rowContent) {
    contentRow.add(TableViewCell(
        child: rowContent.fieldName is String
            ? Text(rowContent.fieldName, textAlign: TextAlign.center)
            : rowContent.fieldName as Widget));
  }
  tableViewCells.add(contentRow);
  contentRow = [];
  // add data to table
  for (final (fieldIndex, field) in tableData.rowContent.indexed) {
    // add boilerplate code and key (for testing) to fields
    contentRow.add(TableViewCell(
        child: field is String
            ? Text(field.fieldContent,
                key: Key(
                    '${tableData.rowContent[fieldIndex].fieldName}$fieldIndex'))
            : field.fieldContent as Widget));
  }
  tableViewCells.add(contentRow);

  // calculate the single field width in percetage of the screen width
  double width = MediaQuery.of(context).size.width;
  List<double> result = [];
  for (final p in tableData.rowContent) {
    result.add(width / 100 * p.fieldWidth);
  }
  // provide row height if requested
  return (tableViewCells, result, tableData.rowHeight);
}

(List<List<TableViewCell>>, List<double>, double? height) get2dTableData<T>(
  // a list is strings or widgets used as column headers
  List<dynamic> Function(
          {int? itemIndex,
          String? classificationId,
          T? item,
          BuildContext? context})
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
  List<Widget> Function({
    Bloc<dynamic, dynamic>? bloc,
    BuildContext? context,
    T? item,
    int? itemIndex,
  })? getRowActionButtons,
  // extra parameters
  BuildContext? context,
  Bloc? bloc,
}) {
  // check if input parameters consistent
  if (kDebugMode && items.isNotEmpty) {
    int itemsName =
        getItemFieldNames(context: context, itemIndex: 0, item: items[0])
            .length;
    int itemsWidth =
        getItemFieldWidth(itemIndex: 0, item: items[0], context: context)
            .length;
    int itemsContent =
        getItemFieldContent(items[0], itemIndex: 0, context: context).length;
    if (itemsName != itemsWidth ||
        itemsName != itemsContent + 1 ||
        itemsWidth != itemsContent + 1) {
      throw FormatException("Generate table parameters:\n"
          "The number of field names($itemsName) is "
          "not the same as number of fields width($itemsWidth) "
          " or number of field contents($itemsContent) + buttons(1)");
    }
  }
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
        contentRow.add(TableViewCell(
            child: name is String
                ? Text(name, textAlign: TextAlign.center)
                : name as Widget));
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
                  itemIndex: itemIndex,
                  item: item,
                  context: context!,
                  bloc: bloc!))));

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
