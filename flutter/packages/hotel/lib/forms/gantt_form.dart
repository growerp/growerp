/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:date_utils/date_utils.dart' as utils;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';

const day = 1, week = 2, month = 3; // columnPeriod values

late int chartInDays;
late int chartColumns; // total columns on chart
late int columnsOnScreen; // periods plus room column

class GanttForm extends StatefulWidget {
  const GanttForm({super.key});
  @override
  State<StatefulWidget> createState() {
    return GanttPageState();
  }
}

class GanttPageState extends State<GanttForm> {
  late DateTime ganttFromDate;
  late int columnPeriod; //day,  week, month
  late FinDocBloc _finDocBloc;
  late AssetBloc _assetBloc;

  @override
  void initState() {
    super.initState();
    columnPeriod = day;
    _finDocBloc = context.read<FinDocBloc>();
    _finDocBloc.add(const FinDocFetch());
    _assetBloc = context.read<AssetBloc>();
    _assetBloc.add(const AssetFetch());
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    DateTime now = CustomizableDateTime.current;
    DateTime nowDate = DateTime(now.year, now.month, now.day, 14, 0, 0, 0);
    switch (columnPeriod) {
      case month:
        if (screenWidth < 800) {
          columnsOnScreen = 4;
        } else {
          columnsOnScreen = 8;
        }
        chartColumns = 13;
        chartInDays = 365;
        ganttFromDate = DateTime(now.year, now.month, 1, 14, 0, 0, 0);
        break;
      case week:
        if (screenWidth < 800) {
          chartColumns = 14;
          columnsOnScreen = 4;
        } else {
          chartColumns = 21;
          columnsOnScreen = 8;
        }
        chartInDays = chartColumns * 7;
        ganttFromDate = nowDate.subtract(Duration(days: nowDate.weekday));
        break;
      case day:
        if (screenWidth < 800) {
          chartColumns = 18;
          columnsOnScreen = 5;
        } else {
          chartColumns = 36;
          columnsOnScreen = 21;
        }
        chartInDays = chartColumns;
        ganttFromDate = nowDate;
        break;
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          key: const Key("addNew"),
          onPressed: () async {
            await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return BlocProvider.value(
                      value: _finDocBloc,
                      child: ReservationDialog(
                          finDoc: FinDoc(
                              sales: true,
                              docType: FinDocType.order,
                              items: [])));
                });
          },
          tooltip: 'Add New',
          child: const Icon(Icons.add)),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          SizedBox(
            height: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => columnPeriod = day),
                  child: const Text('Day'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(() => columnPeriod = week),
                  child: const Text('Week'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(() => columnPeriod = month),
                  child: const Text('Month'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(
                      () => _finDocBloc.add(const FinDocFetch(refresh: true))),
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: GanttChart(
              columnPeriod: columnPeriod,
              ganttFromDate: ganttFromDate,
            ),
          ),
        ],
      ),
    );
  }
}

class GanttChart extends StatelessWidget {
  final int columnPeriod; // day/week/month
  final DateTime ganttFromDate; //earliest date on gannt

  const GanttChart({
    super.key,
    required this.columnPeriod,
    required this.ganttFromDate,
  });

  @override
  Widget build(BuildContext context) {
    List<Asset> assets = [];
    List<FinDoc> finDocs = [];
    List<FinDoc> reservations = [];
    return BlocBuilder<AssetBloc, AssetState>(builder: (context, state) {
      if (state.status == AssetStatus.success) {
        assets = state.assets;
        if (assets.isEmpty) {
          return const Center(child: Text("No Rooms found!"));
        }
        // sort by room number
        assets
            .sort((a, b) => (a.assetName ?? '?').compareTo(b.assetName ?? '?'));
        return BlocBuilder<FinDocBloc, FinDocState>(builder: (context, state) {
          if (state.status == FinDocStatus.success) {
            finDocs = state.finDocs;
            reservations = [];
            for (var asset in assets) {
              for (var finDoc in finDocs) {
                if (finDoc.status != FinDocStatusVal.created ||
                    finDoc.status != FinDocStatusVal.approved) {
                  // create a findoc for every item
                  for (var item in finDoc.items) {
                    if (item.assetId == asset.assetId &&
                        item.rentalFromDate != null &&
                        item.rentalThruDate != null) {
                      reservations.add(finDoc.copyWith(items: [item]));
                    }
                  }
                }
              }
            }
            var screenWidth = MediaQuery.of(context).size.width;
            var chartBars =
                buildAssetBars(context, screenWidth, reservations, finDocs);
            return SizedBox(
              height: chartBars.length * 29.0 + 25.0 + 4.0,
              child: ListView(
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Stack(fit: StackFit.loose, children: <Widget>[
                    buildGrid(screenWidth),
                    buildHeader(screenWidth, Colors.lightGreen),
                    Container(
                        margin: const EdgeInsets.only(top: 25.0),
                        child: Column(
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: chartBars,
                            ),
                          ],
                        )),
                  ]),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
      }
      return const Center(child: CircularProgressIndicator());
    });
  }

  Widget buildGrid(double screenWidth) {
    List<Widget> gridColumns = [];

    for (int i = 0; i <= chartColumns; i++) {
      gridColumns.add(Container(
        decoration: BoxDecoration(
            border: Border(
                right:
                    BorderSide(color: Colors.grey.withAlpha(100), width: 1.0))),
        width: screenWidth / columnsOnScreen,
        // height: 300.0,
      ));
    }

    return Row(
      children: gridColumns,
    );
  }

  Widget buildHeader(double screenWidth, Color color) {
    List<Widget> headerItems = [];

    DateTime? tempDate = ganttFromDate;

    headerItems.add(SizedBox(
      width: screenWidth / columnsOnScreen,
      child: const Text(
        'Room',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.0,
        ),
      ),
    ));

    const List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    const List<String> days = ["Sun", "Mon", "Tue", "Wen", "Thu", "Fri", "Sat"];
    late String headerText;
    int year = ganttFromDate.year;
    for (int i = 0; i < chartColumns; i++) {
      if (columnPeriod == month) {
        headerText = '${months[(ganttFromDate.month + i - 1) % 12]} $year';
        if ((ganttFromDate.month + i) == 12) year++;
      }
      var formatter = DateFormat('yy-MM-dd');
      if (columnPeriod == week) {
        headerText =
            'Week starting: ${days[(ganttFromDate.weekday) % 7]}\n${formatter.format(ganttFromDate.add(Duration(days: i * 7)))}';
      }
      if (columnPeriod == day) {
        headerText =
            '${days[(ganttFromDate.weekday + i) % 7]}\n${formatter.format(ganttFromDate.add(Duration(days: i)))}';
      }
      headerItems.add(SizedBox(
        width: screenWidth / columnsOnScreen,
        child: Text(
          headerText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.0,
          ),
        ),
      ));
      tempDate = utils.DateUtils.nextMonth(tempDate!);
    }

    return Container(
      height: 25.0,
      color: color.withAlpha(100),
      child: Row(
        children: headerItems,
      ),
    );
  }

  List<Widget> buildAssetBars(context, double screenWidth,
      List<FinDoc> reservations, List<FinDoc> finDocs) {
    List<Widget> chartBars = [];
    FinDoc? last;
    for (int i = 0; i < reservations.length; i++) {
      if (last != null &&
          reservations[i].items[0].assetId == last.items[0].assetId) continue;
      // only process assets here, all reservation per asset in buildAssetReservations
      last = reservations[i];
      chartBars.add(Row(children: <Widget>[
        SizedBox(
          height: 20,
          width: screenWidth / columnsOnScreen,
          child: Text(
            reservations[i].items[0].assetName ??
                "${reservations[i].items[0].assetId}",
            textAlign: TextAlign.center,
          ),
        ),
        Row(
            children: buildAssetReservations(
                context, i, screenWidth, reservations, finDocs)),
      ]));
    }
    return chartBars;
  }

  List<Widget> buildAssetReservations(BuildContext context, int startIndex,
      double screenWidth, List<FinDoc> reservations, List<FinDoc> finDocs) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    if (reservations[startIndex].items[0].rentalFromDate == null) {
      return []; // no reservations for this asset
    }
    DateTime lastDate = ganttFromDate.subtract(const Duration(days: 1));
    List<Widget> chartContent = [];
    int index = startIndex;
    // define the scale of 1 day
    late double dayScale;
    if (columnPeriod == day) dayScale = screenWidth / columnsOnScreen;
    if (columnPeriod == week) dayScale = screenWidth / (columnsOnScreen * 7);
    if (columnPeriod == month) {
      dayScale = screenWidth / (columnsOnScreen * 365 / 12);
    }
    double halfDay = dayScale / 2;
    while (index < reservations.length &&
        reservations[index].items[0].assetId ==
            reservations[startIndex].items[0].assetId) {
      DateTime from = reservations[index].items[0].rentalFromDate!;
      DateTime thru = reservations[index].items[0].rentalThruDate!;
      if (from.difference(lastDate).inDays < 0) {
        index++;
        continue;
      }
      BorderRadius borderRadius = BorderRadius.circular(10.0);
      if (from.difference(ganttFromDate).inDays < 0) {
        borderRadius = const BorderRadius.only(
            topRight: Radius.circular(10.0),
            bottomRight: Radius.circular(10.0));
      }
      // save local copy for onTap below
      FinDoc reservation = reservations[index];
      chartContent.add(MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
              onTap: () {
                FinDoc original = finDocs
                    .firstWhere((item) => item.orderId == reservation.orderId);
                showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return BlocProvider.value(
                          value: finDocBloc,
                          child: ReservationDialog(
                              original: original, finDoc: reservation));
                    });
              },
              child: Container(
                // bar on screen
                decoration: BoxDecoration(
                    color: reservations[index].status == FinDocStatusVal.created
                        ? Theme.of(context).focusColor
                        : reservations[index].status == FinDocStatusVal.approved
                            ? Theme.of(context).canvasColor
                            : Theme.of(context).cardColor,
                    borderRadius: borderRadius),
                height: 20.0,
                width: from.difference(ganttFromDate).inDays < 0
                    ? (thru.difference(from).inDays +
                                from.difference(ganttFromDate).inDays) *
                            dayScale +
                        halfDay
                    : (thru.difference(from).inDays) * dayScale,
                margin: EdgeInsets.only(
                    left: from.difference(ganttFromDate).inDays < 0
                        ? (from.difference(lastDate).inDays) * dayScale
                        : (from.difference(lastDate).inDays) * dayScale +
                            halfDay,
                    top: 4.0,
                    bottom: 4.0),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "${reservations[index].orderId} "
                    " ${reservations[index].otherUser!.firstName}"
                    " ${reservations[index].otherUser!.lastName}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.0),
                  ),
                ),
              ))));
      lastDate = reservations[index].items[0].rentalThruDate as DateTime;
      index++;
      halfDay = 0.00;
    }
    return chartContent;
  }
}
