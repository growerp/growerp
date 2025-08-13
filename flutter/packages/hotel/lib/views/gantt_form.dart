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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';

enum Period { day, week, month }

class GanttForm extends StatefulWidget {
  const GanttForm({super.key});

  @override
  State<GanttForm> createState() => _GanttFormState();
}

class _GanttFormState extends State<GanttForm> {
  late DateTime ganttFromDate;
  late Period columnPeriod; //day,  week, month
  late SalesOrderBloc _salesOrderBloc;
  late AssetBloc _assetBloc;
  late FinDocBloc _finDocBloc;
  List<Asset> assets = [];
  List<FinDoc> finDocs = [];
  List<FinDoc> reservations = [];
  List<ProductRentalDate> productRentalDates = [];
  List<Widget> chartContent = [];
  int itemCount = 0;
  late double screenWidth;
  late ColorScheme scheme;
  late int chartInDays;
  late int chartColumns; // total columns on chart
  late int columnsOnScreen; // periods
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    columnPeriod = Period.day;
    _salesOrderBloc = context.read<SalesOrderBloc>()..add(const FinDocFetch());
    _assetBloc = context.read<AssetBloc>()
      ..add(const AssetFetch(refresh: true));
    _finDocBloc = context.read<FinDocBloc>()
      ..add(const FinDocProductRentalDates(null));

    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    right = right ?? (isAPhone(context) ? 20 : 50);

    scheme = Theme.of(context).colorScheme;
    return BlocBuilder<FinDocBloc, FinDocState>(
      builder: (context, finDocState) {
        return BlocBuilder<AssetBloc, AssetState>(
          builder: (context, assetState) {
            return BlocConsumer<SalesOrderBloc, FinDocState>(
              listener: (context, salesOrderState) {
                switch (salesOrderState.status) {
                  case FinDocStatus.success:
                    HelperFunctions.showMessage(
                      context,
                      '${"Update"} successfull',
                      Colors.green,
                    );
                  case FinDocStatus.failure:
                    HelperFunctions.showMessage(
                      context,
                      'Error: ${finDocState.message}',
                      Colors.red,
                    );
                  default:
                }
              },
              builder: (context, salesOrderState) {
                if (finDocState.status == FinDocStatus.success &&
                    salesOrderState.status == FinDocStatus.success &&
                    assetState.status == AssetStatus.success) {
                  itemCount = 0;
                  reservations = [];
                  assets = assetState.assets;
                  productRentalDates = finDocState.productRentalDates;
                  finDocs = salesOrderState.finDocs;

                  // group all open reservations by Room number as a single item
                  assets = List.of(assets);
                  assets.sort(
                    (a, b) =>
                        (a.assetName ?? '?').compareTo(b.assetName ?? '?'),
                  );
                  for (var asset in assets) {
                    itemCount++;
                    bool hasReservation = false;
                    for (var finDoc in finDocs) {
                      if (finDoc.status == FinDocStatusVal.created ||
                          finDoc.status == FinDocStatusVal.approved) {
                        // create a findoc for every item
                        for (var item in finDoc.items) {
                          if (item.asset!.assetId == asset.assetId &&
                              item.rentalFromDate != null &&
                              item.rentalThruDate != null) {
                            reservations.add(
                              finDoc.copyWith(
                                shipmentId: itemCount.toString(),
                                items: [item],
                              ),
                            );
                            hasReservation = true;
                          }
                        }
                      }
                    }
                    if (!hasReservation) {
                      reservations.add(
                        FinDoc(
                          shipmentId: itemCount.toString(),
                          items: [
                            FinDocItem(
                              asset: Asset(
                                assetId: asset.assetId,
                                assetName: asset.assetName,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  DateTime nowDate = CustomizableDateTime.current;
                  switch (columnPeriod) {
                    case Period.month:
                      if (screenWidth < 800) {
                        columnsOnScreen = 4;
                      } else {
                        columnsOnScreen = 8;
                      }
                      chartColumns = 13;
                      chartInDays = 365;
                      ganttFromDate = nowDate;
                    case Period.week:
                      if (screenWidth < 800) {
                        chartColumns = 14;
                        columnsOnScreen = 4;
                      } else {
                        chartColumns = 21;
                        columnsOnScreen = 8;
                      }
                      chartInDays = chartColumns * 7;
                      ganttFromDate = nowDate.subtract(
                        Duration(days: nowDate.weekday),
                      );
                    case Period.day:
                      if (screenWidth < 800) {
                        chartColumns = 60;
                        columnsOnScreen = 5;
                      } else {
                        chartColumns = 60;
                        columnsOnScreen = 16;
                      }
                      chartInDays = chartColumns;
                      ganttFromDate = nowDate;
                  }

                  return Stack(
                    children: [
                      Column(
                        children: <Widget>[
                          Expanded(
                            child: HorizontalDataTable(
                              leftHandSideColumnWidth: 80,
                              rightHandSideColumnWidth:
                                  chartColumns * screenWidth / columnsOnScreen,
                              isFixedHeader: true,
                              headerWidgets: _getHeaderWidget(),
                              leftSideItemBuilder: _generateFirstColumnRow,
                              rightSideItemBuilder: buildAssetReservation,
                              itemCount: itemCount + 1,
                              itemExtent: 20,
                              leftHandSideColBackgroundColor: scheme.surface,
                              rightHandSideColBackgroundColor: scheme.surface,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: right,
                        bottom: bottom,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              right = right! - details.delta.dx;
                              bottom -= details.delta.dy;
                            });
                          },
                          child: Column(
                            children: [
                              if (columnPeriod != Period.day &&
                                  assetState.assets.isNotEmpty)
                                FloatingActionButton(
                                  heroTag: 'day',
                                  key: const Key("day"),
                                  onPressed: () =>
                                      setState(() => columnPeriod = Period.day),
                                  tooltip: 'Chart by Day',
                                  child: const Text('Day'),
                                ),
                              const SizedBox(height: 5),
                              if (columnPeriod != Period.week &&
                                  assetState.assets.isNotEmpty)
                                FloatingActionButton(
                                  heroTag: 'week',
                                  key: const Key("week"),
                                  onPressed: () => setState(
                                    () => columnPeriod = Period.week,
                                  ),
                                  tooltip: 'Chart by Week',
                                  child: const Text('Week'),
                                ),
                              const SizedBox(height: 5),
                              if (columnPeriod != Period.month &&
                                  assetState.assets.isNotEmpty)
                                FloatingActionButton(
                                  heroTag: 'month',
                                  key: const Key("month"),
                                  onPressed: () => setState(
                                    () => columnPeriod = Period.month,
                                  ),
                                  tooltip: 'Chart by Month',
                                  child: const Text('Month'),
                                ),
                              const SizedBox(height: 5),
                              FloatingActionButton(
                                heroTag: 'refresh',
                                key: const Key("refresh"),
                                onPressed: () {
                                  _salesOrderBloc.add(
                                    const FinDocFetch(refresh: true),
                                  );
                                  _assetBloc.add(
                                    const AssetFetch(refresh: true),
                                  );
                                  _finDocBloc.add(
                                    const FinDocProductRentalDates(null),
                                  );
                                  setState(() {});
                                  return;
                                },
                                tooltip: 'Chart by day',
                                child: const Icon(Icons.refresh),
                              ),
                              const SizedBox(height: 5),
                              if (assetState.assets.isNotEmpty)
                                FloatingActionButton(
                                  heroTag: 'addnew',
                                  key: const Key("addNew"),
                                  onPressed: () async {
                                    await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _finDocBloc,
                                          child: BlocProvider.value(
                                            value: _salesOrderBloc,
                                            child: ReservationDialog(
                                              finDoc: FinDoc(
                                                sales: true,
                                                docType: FinDocType.order,
                                                items: [],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  tooltip: 'Add New',
                                  child: const Icon(Icons.add),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (assetState.assets.isEmpty)
                        const Column(
                          children: [
                            SizedBox(height: 10),
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                "No Rooms found,\n goto to the room section to add:\n"
                                "1. room types\n"
                                "2. actual rooms related to room types",
                                style: TextStyle(fontSize: 20.0),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                }
                return const Center(child: LoadingIndicator());
              },
            );
          },
        );
      },
    );
  }

  Widget buildGrid() {
    List<Widget> gridColumns = [];

    for (int i = 0; i <= chartColumns - 1; i++) {
      gridColumns.add(
        Container(
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: scheme.inversePrimary, width: 1.0),
            ),
          ),
          width: screenWidth / columnsOnScreen,
        ),
      );
    }

    return Row(children: gridColumns);
  }

  List<Widget> _getHeaderWidget() {
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
      "Dec",
    ];
    const List<String> days = ["Sun", "Mon", "Tue", "Wen", "Thu", "Fri", "Sat"];
    late String headerText;
    int year = ganttFromDate.year;
    List<Widget> headerItems = [
      const SizedBox(
        height: 30,
        child: Text('Type/Name', textAlign: TextAlign.center),
      ),
    ];
    DateTime? tempDate = ganttFromDate;
    for (int i = 0; i < chartColumns; i++) {
      if (columnPeriod == Period.month) {
        headerText = '${months[(ganttFromDate.month + i - 1) % 12]} $year';
        if ((ganttFromDate.month + i) == 12) year++;
      }
      var formatter = DateFormat('yyyy-MM-dd');
      if (columnPeriod == Period.week) {
        headerText =
            'Week starting:\n${days[(ganttFromDate.weekday) % 7]} ${formatter.format(ganttFromDate.add(Duration(days: i * 7)))}';
      }
      if (columnPeriod == Period.day) {
        headerText =
            '${days[(ganttFromDate.weekday + i) % 7]}\n${formatter.format(ganttFromDate.add(Duration(days: i)))}';
      }
      headerItems.add(
        Container(
          height: 30,
          color: Colors.lightGreen.withAlpha(100),
          width: screenWidth / columnsOnScreen,
          child: Text(
            headerText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.0),
          ),
        ),
      );
      tempDate = DateTime(tempDate!.year, tempDate.month - 1, tempDate.day);
    }
    return headerItems;
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {
    String columnText = '';
    if (index < productRentalDates.length) {
      columnText = productRentalDates[index].productName ?? '';
    } else if (index == productRentalDates.length) {
    } else {
      var roomReservation = reservations.firstWhere(
        (element) =>
            int.parse(element.shipmentId ?? '') ==
            index - productRentalDates.length,
      );
      columnText = roomReservation.items[0].asset?.assetName ?? '';
    }
    return Container(
      color: Colors.lightGreen.withAlpha(100),
      width: 80,
      height: 20,
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.centerLeft,
      child: Text(columnText),
    );
  }

  /// print single bar depending on the start and end rental dates for
  /// either by product (room type) or asset(room)
  Widget buildAssetReservation(BuildContext context, int index) {
    chartContent = [];
    List<Widget> chartLine = [];
    // define the scale of 1 day
    late double dayScale;
    if (columnPeriod == Period.day) dayScale = screenWidth / columnsOnScreen;
    if (columnPeriod == Period.week) {
      dayScale = screenWidth / (columnsOnScreen * 7);
    }
    if (columnPeriod == Period.month) {
      dayScale = screenWidth / (columnsOnScreen * 365 / 12);
    }
    DateTime ganttFromDateMin1day = ganttFromDate.subtract(
      const Duration(days: 1),
    );

    double halfDay = dayScale / 2;
    // show occupancy full bars
    if (index < productRentalDates.length) {
      ProductRentalDate productRentalDate = productRentalDates[index];
      for (final from in productRentalDate.dates) {
        if (from.difference(ganttFromDate).inDays < -1) continue;
        BorderRadius borderRadius = BorderRadius.circular(10.0);
        if (from.difference(ganttFromDate).inDays < 0) {
          borderRadius = const BorderRadius.only(
            topRight: Radius.circular(10.0),
            bottomRight: Radius.circular(10.0),
          );
        }
        chartLine.add(
          Container(
            // bar on screen
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: borderRadius,
            ),
            height: 18.0,
            width: from.difference(ganttFromDate).inDays < 0
                ? halfDay
                : dayScale,
            margin: EdgeInsets.only(
              // spacing from the left
              left: from.difference(ganttFromDate).inDays < 0
                  ? from.difference(ganttFromDateMin1day).inDays * dayScale
                  : from.difference(ganttFromDateMin1day).inDays * dayScale +
                        halfDay,
              top: 1.0,
              bottom: 1.0,
            ),
            alignment: Alignment.centerLeft,
          ),
        );
      }
    } else if (index == productRentalDates.length) {
      chartLine.add(const SizedBox(height: 18, width: 1));
    } // blank line
    // show reservations
    else if (index > productRentalDates.length) {
      FinDoc reservation = reservations[index - productRentalDates.length - 1];
      /*debugPrint(
        "==${reservation.shipmentId}==room: ${reservation.items[0].asset?.assetName} "
        "orderId: ${reservation.orderId} "
        "fr:${reservation.items[0].rentalFromDate.dateOnly()} "
        "to: ${reservation.items[0].rentalThruDate.dateOnly()}",
      );*/
      // occupation by product
      if (reservation.items[0].rentalFromDate != null &&
          reservation.items[0].rentalThruDate!
                  .difference(ganttFromDate)
                  .inDays >=
              0) {
        // show occupation by room(asset) ==================================
        //roomReservations.sort((b, a) => (a.items[0].rentalFromDate.dateOnly())
        //    .compareTo(b.items[0].rentalFromDate.dateOnly()));
        DateTime from = reservation.items[0].rentalFromDate!;
        DateTime thru = reservation.items[0].rentalThruDate!;
        // started before today only borderradius on the right
        BorderRadius borderRadius = BorderRadius.circular(10.0);
        if (from.difference(ganttFromDateMin1day).inDays < 0) {
          borderRadius = const BorderRadius.only(
            topRight: Radius.circular(10.0),
            bottomRight: Radius.circular(10.0),
          );
          from = ganttFromDate;
        }
        chartLine.add(
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FinDoc original = finDocs.firstWhere(
                  (FinDoc item) => item.orderId == reservation.orderId,
                );
                showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider.value(
                      value: _finDocBloc,
                      child: BlocProvider.value(
                        value: _salesOrderBloc,
                        child: ReservationDialog(finDoc: original),
                      ),
                    );
                  },
                );
              },
              child: Container(
                // bar on screen
                decoration: BoxDecoration(
                  color: Colors.lightGreen,
                  borderRadius: borderRadius,
                ),
                height: 18.0,
                width: from.difference(ganttFromDate).inDays < 0
                    ? thru.difference(from).inDays * dayScale + halfDay
                    : thru.difference(from).inDays * dayScale,
                margin: EdgeInsets.only(
                  left: from.difference(ganttFromDate).inDays < 0
                      ? from.difference(ganttFromDateMin1day).inDays * dayScale
                      : from.difference(ganttFromDateMin1day).inDays *
                                dayScale +
                            halfDay,
                  top: 1.0,
                  bottom: 1.0,
                ),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "${reservation.pseudoId} "
                    " ${reservation.otherCompany?.name ?? ''}"
                    " ${reservation.otherUser?.firstName ?? ''}"
                    " ${reservation.otherUser?.lastName ?? ''}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.0),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // empty lines =====================================================
        chartLine.add(const SizedBox(height: 18, width: 1));
      }
    }
    chartContent.add(Stack(children: chartLine));
    return Stack(
      children: [
        buildGrid(),
        Row(children: chartContent),
      ],
    );
  }
}
