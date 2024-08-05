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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// a program to generate the structure for the TableView,builder 2d scrollable

/// Input data definition
class TableData {
  final double rowHeight;
  final List<TableRowContent> rowContent; // name,width,content,action buttons
  TableData({
    required this.rowHeight,
    required this.rowContent,
  });
}

/// Table field definition
class TableRowContent {
  final dynamic name; // can be string or widget
  final double width;
  final dynamic value;

  TableRowContent({
    required this.width,
    required this.name,
    required this.value,
  });
}

(List<List<TableViewCell>>, List<double>, double? height) get2dTableData<T>(
    TableData Function(Bloc bloc, String classificationId, BuildContext context,
            T item, int index,
            {dynamic extra})
        getTableData,
    {required Bloc bloc,
    required String classificationId,
    required BuildContext context,
    required List<T> items,
    double? screenWidth,
    dynamic extra}) {
  double width = screenWidth ?? MediaQuery.of(context).size.width;
  List<double> fieldWidth = [];
  late TableData tableData;
  List<List<TableViewCell>> tableViewCells = []; // table content
  List<TableViewCell> contentRow = []; // row content
  // create table content headers
  for (final (rowIndex, item) in items.indexed) {
    tableData = getTableData(bloc, classificationId, context, item, rowIndex,
        extra: extra);
    if (rowIndex == 0) {
      for (final fieldContent in tableData.rowContent) {
        // add header
        contentRow.add(TableViewCell(
            child: fieldContent.name is String
                ? Text(fieldContent.name, textAlign: TextAlign.left)
                : fieldContent.name as Widget));
      }
      tableViewCells.add(contentRow);
      contentRow = [];

      // field width
      for (final field in tableData.rowContent) {
        fieldWidth
            .add(width / 100 * field.width); // use percetage of screen width
      }
    }
    // add data to table
    for (final fieldContent in tableData.rowContent) {
      contentRow.add(TableViewCell(
          child: fieldContent.value is String
              ? Text(fieldContent.value,
                  textAlign: TextAlign.left,
                  key: Key('${tableData.rowContent.first.name}$rowIndex'))
              : fieldContent.value as Widget));
    }
    tableViewCells.add(contentRow);
    contentRow = [];
  }
  return (tableViewCells, fieldWidth, items.isEmpty ? 0 : tableData.rowHeight);
}
