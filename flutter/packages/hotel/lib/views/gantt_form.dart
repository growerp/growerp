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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';

enum Period { day, week, month }

class GanttForm extends StatefulWidget {
  const GanttForm({
    super.key,
  });

  @override
  State<GanttForm> createState() => _GanttFormState();
}

class _GanttFormState extends State<GanttForm> {
  late DateTime ganttFromDate;
  late Period columnPeriod; //day,  week, month
  late FinDocBloc _finDocBloc;
  late AssetBloc _assetBloc;
  late ProductBloc _productBloc;
  List<Asset> assets = [];
  List<FinDoc> finDocs = [];
  List<FinDoc> reservations = [];
  List<Product> productFullDates = [];
  List<Widget> chartContent = [];
  int itemCount = 0;
  late double screenWidth;
  late ColorScheme scheme;
  late int chartInDays;
  late int chartColumns; // total columns on chart
  late int columnsOnScreen; // periods

  @override
  void initState() {
    columnPeriod = Period.day;
    _finDocBloc = context.read<FinDocBloc>();
    _finDocBloc.add(const FinDocFetch());
    _assetBloc = context.read<AssetBloc>();
    _assetBloc.add(const AssetFetch(assetClassId: 'Hotel Room'));
    _productBloc = context.read<ProductBloc>()
      ..add(const ProductRentalOccupancy());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    scheme = Theme.of(context).colorScheme;
    return BlocBuilder<AssetBloc, AssetState>(builder: (context, assetState) {
      return BlocBuilder<FinDocBloc, FinDocState>(
          builder: (context, finDocState) {
        return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
          if (finDocState.status == FinDocStatus.success &&
              productState.status == ProductStatus.success &&
              assetState.status == AssetStatus.success) {
            if (assetState.assets.isEmpty) {
              return Column(children: [
                const SizedBox(height: 10),
                ganttButtons(),
                const SizedBox(height: 200),
                const Center(child: Text("No Rooms found!")),
              ]);
            }
            itemCount = 0;
            reservations = [];
            assets = assetState.assets;
            productFullDates = productState.productFullDates;
            finDocs = finDocState.finDocs;
            // all open reservations combined by Room type(product) in the server
            for (var fullDate in productFullDates) {
              reservations
                  .add(FinDoc(shipmentId: (itemCount++).toString(), items: [
                FinDocItem(
                    asset: Asset(
                        assetId: fullDate.productId,
                        assetName: fullDate.productName),
                    description: '!!${fullDate.fullDates.join(',')}')
              ])); // space
            }

            reservations.add(FinDoc(
                shipmentId: (itemCount++).toString(),
                items: [
                  FinDocItem(asset: Asset(assetId: '', assetName: ''))
                ])); // space

            // group all open reservations by Room number as a single item
            assets = List.of(assets);
            assets.sort(
                (a, b) => (a.assetName ?? '?').compareTo(b.assetName ?? '?'));
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
                      reservations.add(finDoc.copyWith(
                          shipmentId: itemCount.toString(), items: [item]));
                      hasReservation = true;
                    }
                  }
                }
              }
              if (!hasReservation) {
                reservations.add(FinDoc(
                    shipmentId: itemCount.toString(),
                    items: [
                      FinDocItem(
                          asset: Asset(
                              assetId: asset.assetId,
                              assetName: asset.assetName))
                    ]));
              }
            }
            DateTime now = CustomizableDateTime.current;
            DateTime nowDate =
                DateTime(now.year, now.month, now.day, 14, 0, 0, 0);
            switch (columnPeriod) {
              case Period.month:
                if (screenWidth < 800) {
                  columnsOnScreen = 4;
                } else {
                  columnsOnScreen = 8;
                }
                chartColumns = 13;
                chartInDays = 365;
                ganttFromDate = DateTime(now.year, now.month, 1, 14, 0, 0, 0);
                break;
              case Period.week:
                if (screenWidth < 800) {
                  chartColumns = 14;
                  columnsOnScreen = 4;
                } else {
                  chartColumns = 21;
                  columnsOnScreen = 8;
                }
                chartInDays = chartColumns * 7;
                ganttFromDate =
                    nowDate.subtract(Duration(days: nowDate.weekday));
                break;
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
                break;
            }
            double top = 0;
            double left = 250;
            return Stack(
              children: [
                Column(children: <Widget>[
                  const SizedBox(height: 10),
                  ganttButtons(),
                  const SizedBox(height: 5),
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
                  )
                ]),
                Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        left += details.delta.dx;
                        top += details.delta.dy;
                      });
                    },
                    child: FloatingActionButton(
                        key: const Key("addNew"),
                        onPressed: () async {
                          await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _productBloc,
                                  child: BlocProvider.value(
                                      value: _finDocBloc,
                                      child: ReservationDialog(
                                          finDoc: FinDoc(
                                              sales: true,
                                              docType: FinDocType.order,
                                              items: []))),
                                );
                              });
                        },
                        tooltip: 'Add New',
                        child: const Icon(Icons.add)),
                  ),
                ),
              ],
            );
          }
          return const Center(child: LoadingIndicator());
        });
      });
    });
  }

  SizedBox ganttButtons() {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => setState(() => columnPeriod = Period.day),
            child: const Text('Day'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => setState(() => columnPeriod = Period.week),
            child: const Text('Week'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => setState(() => columnPeriod = Period.month),
            child: const Text('Month'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            key: const Key('refresh'),
            onPressed: () {
              _finDocBloc.add(const FinDocFetch(refresh: true));
              _assetBloc.add(const AssetFetch(refresh: true));
              _productBloc.add(const ProductRentalOccupancy());
              setState(() {});
              return;
            },
            child: const Text('Refresh'),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget buildGrid() {
    List<Widget> gridColumns = [];

    for (int i = 0; i <= chartColumns - 1; i++) {
      gridColumns.add(Container(
        height: 20,
        decoration: BoxDecoration(
            border: Border(
                left: BorderSide(color: scheme.inversePrimary, width: 1.0))),
        width: screenWidth / columnsOnScreen,
      ));
    }

    return Row(
      children: gridColumns,
    );
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
      "Dec"
    ];
    const List<String> days = ["Sun", "Mon", "Tue", "Wen", "Thu", "Fri", "Sat"];
    late String headerText;
    int year = ganttFromDate.year;
    List<Widget> headerItems = [
      const SizedBox(
        height: 30,
        child: Text(
          'Type/Name',
          textAlign: TextAlign.center,
        ),
      )
    ];
    DateTime? tempDate = ganttFromDate;
    for (int i = 0; i < chartColumns; i++) {
      if (columnPeriod == Period.month) {
        headerText = '${months[(ganttFromDate.month + i - 1) % 12]} $year';
        if ((ganttFromDate.month + i) == 12) year++;
      }
      var formatter = DateFormat('yy-MM-dd');
      if (columnPeriod == Period.week) {
        headerText =
            'Week starting:\n${days[(ganttFromDate.weekday) % 7]} ${formatter.format(ganttFromDate.add(Duration(days: i * 7)))}';
      }
      if (columnPeriod == Period.day) {
        headerText =
            '${days[(ganttFromDate.weekday + i) % 7]}\n${formatter.format(ganttFromDate.add(Duration(days: i)))}';
      }
      headerItems.add(Container(
        height: 30,
        color: Colors.lightGreen.withAlpha(100),
        width: screenWidth / columnsOnScreen,
        child: Text(
          headerText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.0,
          ),
        ),
      ));
      tempDate = DateTime(tempDate!.year, tempDate.month - 1, tempDate.day);
    }
    return headerItems;
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {
    var roomReservations = reservations
        .where((element) => int.parse(element.shipmentId ?? '') == index)
        .toList();
    return Container(
      color: Colors.lightGreen.withAlpha(100),
      width: 80,
      height: 20,
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.centerLeft,
      child: Text(roomReservations.isEmpty
          ? ''
          : roomReservations[0].items[0].asset!.assetName ?? '??'),
    );
  }

  /// print single bar depending on the start and end rental dates for
  /// either by product (room type) or asset(room)
  Widget buildAssetReservation(BuildContext context, int index) {
    DateTime ganttFromDateMin1day =
        ganttFromDate.subtract(const Duration(days: 1));
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
    double halfDay = dayScale / 2;
    var roomReservations = reservations
        .where((element) => int.parse(element.shipmentId ?? '') == index)
        .toList();
    for (FinDoc reservation in roomReservations) {
      /*  debugPrint(
          "==${reservation.shipmentId}==room: ${reservation.items[0].asset?.assetName} "
          "orderId: ${reservation.orderId} "
          "fr:${reservation.items[0].rentalFromDate?.dateOnly()} "
          "to: ${reservation.items[0].rentalThruDate?.dateOnly()}");
    */ // occupation by product
      if (reservation.items[0].description != null &&
          // all dates concatenated in description
          reservation.items[0].description!.startsWith('!!') &&
          // ignore if empty
          reservation.items[0].description! != '!!') {
        // show full occupation by product ============================
        List dates = reservation.items[0].description!.substring(2).split(',');
        for (String date in dates) {
          if (date.isEmpty) continue;
          DateTime from = DateTime.parse(date);
          if (from.difference(ganttFromDate).inDays < -1) continue;
          BorderRadius borderRadius = BorderRadius.circular(10.0);
          if (from.difference(ganttFromDate).inDays < 0) {
            borderRadius = const BorderRadius.only(
                topRight: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0));
          }
          chartLine.add(Container(
            // bar on screen
            decoration:
                BoxDecoration(color: Colors.red, borderRadius: borderRadius),
            height: 18.0,
            width:
                from.difference(ganttFromDate).inDays < 0 ? halfDay : dayScale,
            margin: EdgeInsets.only(
                // spacing from the left
                left: from.difference(ganttFromDate).inDays < 0
                    ? from.difference(ganttFromDateMin1day).inDays * dayScale
                    : from.difference(ganttFromDateMin1day).inDays * dayScale +
                        halfDay,
                top: 1.0,
                bottom: 1.0),
            alignment: Alignment.centerLeft,
          ));
        }
      } else if (reservation.items[0].rentalFromDate != null &&
          reservation.items[0].rentalThruDate!
                  .difference(ganttFromDate)
                  .inDays >=
              0) {
        // show occupation by room(asset) ==================================
        //roomReservations.sort((b, a) => (a.items[0].rentalFromDate!.dateOnly())
        //    .compareTo(b.items[0].rentalFromDate!.dateOnly()));
        DateTime from = reservation.items[0].rentalFromDate!;
        DateTime thru = reservation.items[0].rentalThruDate!;
        // started before today only borderradius on the right
        BorderRadius borderRadius = BorderRadius.circular(10.0);
        if (from.difference(ganttFromDate).inDays < 0) {
          borderRadius = const BorderRadius.only(
              topRight: Radius.circular(10.0),
              bottomRight: Radius.circular(10.0));
          from = ganttFromDateMin1day;
        }
        chartLine.add(MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FinDoc original = finDocs.firstWhere(
                      (FinDoc item) => item.orderId == reservation.orderId);
                  showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return BlocProvider.value(
                          value: _productBloc,
                          child: BlocProvider.value(
                              value: _finDocBloc,
                              child: ReservationDialog(finDoc: original)),
                        );
                      });
                },
                child: Container(
                  // bar on screen
                  decoration: BoxDecoration(
                      color: Colors.lightGreen, borderRadius: borderRadius),
                  height: 18.0,
                  width: from.difference(ganttFromDate).inDays < 0
                      ? thru.difference(from).inDays * dayScale + halfDay
                      : thru.difference(from).inDays * dayScale,
                  margin: EdgeInsets.only(
                      left: from.difference(ganttFromDate).inDays < 0
                          ? from.difference(ganttFromDateMin1day).inDays *
                              dayScale
                          : from.difference(ganttFromDateMin1day).inDays *
                                  dayScale +
                              halfDay,
                      top: 1.0,
                      bottom: 1.0),
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "${reservation.orderId} "
                      " ${reservation.otherCompany?.name ?? ''}"
                      " ${reservation.otherUser?.firstName ?? ''}"
                      " ${reservation.otherUser?.lastName ?? ''}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.0),
                    ),
                  ),
                ))));
      } else {
        // empty lines =====================================================
        chartLine.add(const SizedBox(
          height: 18,
          width: 1,
        ));
      }
    }
    chartContent.add(Stack(children: chartLine));
    return Stack(children: [buildGrid(), Row(children: chartContent)]);
  }
}
