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
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

const day = 1, week = 2, month = 3; // columnPeriod values

late int chartInDays;
late int chartColumns; // total columns on chart
late int columnsOnScreen; // periods

class GanttForm extends StatelessWidget {
  const GanttForm({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AssetBloc>(
            create: (context) => AssetBloc(CatalogAPIRepository(
                context.read<AuthBloc>().state.authenticate!.apiKey!))),
        BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(CatalogAPIRepository(
                context.read<AuthBloc>().state.authenticate!.apiKey!))),
        BlocProvider<FinDocBloc>(
            create: (context) => FinDocBloc(
                FinDocAPIRepository(
                    context.read<AuthBloc>().state.authenticate!.apiKey),
                true,
                FinDocType.order)),
      ],
      child: const GanttFormFull(),
    );
  }
}

class GanttFormFull extends StatefulWidget {
  const GanttFormFull({super.key});
  @override
  State<StatefulWidget> createState() {
    return GanttPageState();
  }
}

class GanttPageState extends State<GanttFormFull> {
  late DateTime ganttFromDate;
  late int columnPeriod; //day,  week, month
  late FinDocBloc _finDocBloc;
  late AssetBloc _assetBloc;
  late ProductBloc _productBloc;

  @override
  void initState() {
    super.initState();
    columnPeriod = day;
    _finDocBloc = context.read<FinDocBloc>();
    _finDocBloc.add(const FinDocFetch());
    _assetBloc = context.read<AssetBloc>();
    _assetBloc.add(const AssetFetch(assetClassId: 'Hotel Room'));
    _productBloc = context.read<ProductBloc>();
    _productBloc.add(const ProductRentalOccupancy());
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

    return Scaffold(
      floatingActionButton: FloatingActionButton(
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

  Widget buildGrid(double screenWidth) {
    List<Widget> gridColumns = [];

    for (int i = 0; i <= chartColumns; i++) {
      gridColumns.add(Container(
        decoration: BoxDecoration(
            border: Border(
                left:
                    BorderSide(color: Colors.grey.withAlpha(100), width: 1.0))),
        width: screenWidth / columnsOnScreen,
      ));
    }

    return Row(
      children: gridColumns,
    );
  }

  Widget buildHeader(double screenWidth) {
    List<Widget> headerItems = [];

    DateTime? tempDate = ganttFromDate;

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
            'Week starting:\n${days[(ganttFromDate.weekday) % 7]} ${formatter.format(ganttFromDate.add(Duration(days: i * 7)))}';
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
      height: 30.0,
      color: Colors.lightGreen.withAlpha(100),
      child: Row(
        children: headerItems,
      ),
    );
  }

  /// print bars depending on the start and end rental dates for
  /// either by product (room type) or asset(room)
  Widget buildAssetReservation(BuildContext context, double screenWidth,
      List<FinDoc> reservations, List<FinDoc> finDocs) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    ProductBloc productBloc = context.read<ProductBloc>();
    DateTime ganttFromDateMin1day =
        ganttFromDate.subtract(const Duration(days: 1));
    List<Widget> chartContent = [];
    List<Widget> chartLine = [];
    // define the scale of 1 day
    late double dayScale;
    if (columnPeriod == day) dayScale = screenWidth / columnsOnScreen;
    if (columnPeriod == week) dayScale = screenWidth / (columnsOnScreen * 7);
    if (columnPeriod == month) {
      dayScale = screenWidth / (columnsOnScreen * 365 / 12);
    }
    // avoid overlapping of bars of future over earlier.....
    reservations.sort((b, a) => (a.items[0].rentalFromDate!.dateOnly())
        .compareTo(b.items[0].rentalFromDate!.dateOnly()));
    double halfDay = dayScale / 2;
    for (FinDoc reservation in reservations) {
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
        DateTime from = reservation.items[0].rentalFromDate!;
        DateTime thru = reservation.items[0].rentalThruDate!;
//        debugPrint("====room: ${reservation.items[0].assetName} "
//            "orderId: ${reservation.orderId} "
//            "fr:${reservation.items[0].rentalFromDate!.dateOnly()} "
//            "to: ${reservation.items[0].rentalThruDate!.dateOnly()}");
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
                          value: productBloc,
                          child: BlocProvider.value(
                              value: finDocBloc,
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
                      " ${reservation.otherUser!.firstName}"
                      " ${reservation.otherUser!.lastName}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.0),
                    ),
                  ),
                ))));
      } else {
        // empty lines =====================================================
        chartLine.add(const SizedBox(
          height: 20.0,
          width: 1,
        ));
      }
    }
    chartContent.add(Stack(children: chartLine));
    return Row(children: chartContent);
  }

  (Widget leftColomnItem, Widget rightColumnItem) makeColumnItem(
      BuildContext context,
      double screenWidth,
      List<FinDoc> reservations,
      List<FinDoc> finDocs) {
    return (
      SizedBox(
        height: 20,
        width: screenWidth / columnsOnScreen,
        child: reservations[0].items[0].assetName != null
            ? Text(
                reservations[0].items[0].assetName ??
                    "${reservations[0].items[0].assetId}",
                textAlign: TextAlign.left,
              )
            : null,
      ),
      buildAssetReservation(context, screenWidth, reservations, finDocs)
    );
  }

  (List<Widget>, List<Widget>) buildLeftRightColumn(BuildContext context,
      double screenWidth, List<FinDoc> reservations, List<FinDoc> finDocs) {
    List<Widget> leftColumn = [
      Container(
          height: 30.0,
          color: Colors.lightGreen.withAlpha(100),
          child: SizedBox(
            width: screenWidth / columnsOnScreen,
            child: const Text(
              'Room Type\n Room',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.0,
              ),
            ),
          )),
    ];
    List<Widget> rightColumn = [const SizedBox(height: 30)];
    FinDoc? last;
    int start = 0, end = 0;
    reservations.forEachIndexed((i, el) {
      if (last?.sales != null &&
          el.items[0].assetId != last!.items[0].assetId) {
        end = i;
        var (leftColumnItem, rightColumnItem) = makeColumnItem(
            context, screenWidth, reservations.sublist(start, end), finDocs);
        leftColumn.add(leftColumnItem);
        rightColumn.add(rightColumnItem);
        start = i;
      }
      last = el;
    });
    if (last?.sales != null) {
      end = reservations.length;
      var (leftColumnItem, rightColumnItem) = makeColumnItem(
          context, screenWidth, reservations.sublist(start, end), finDocs);
      leftColumn.add(leftColumnItem);
      rightColumn.add(rightColumnItem);
    }
    return (leftColumn, rightColumn);
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    List<Asset> assets = [];
    List<FinDoc> finDocs = [];
    List<FinDoc> reservations = [];
    List<FullDatesProductRental> fullDates = [];
    return BlocBuilder<AssetBloc, AssetState>(builder: (context, assetState) {
      return BlocBuilder<FinDocBloc, FinDocState>(
          builder: (context, finDocState) {
        return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
          if (finDocState.status == FinDocStatus.success &&
              productState.status == ProductStatus.success &&
              assetState.status == AssetStatus.success) {
            if (assetState.assets.isEmpty) {
              return const Center(child: Text("No Rooms found!"));
            }
            assets = assetState.assets;
            fullDates = productState.fullDates;
            finDocs = finDocState.finDocs;
            reservations = [];

            // all open reservations combined by Room type(product) in the server
            for (var fullDate in fullDates) {
              reservations.add(FinDoc(items: [
                FinDocItem(
                    assetId: fullDate.productId,
                    assetName: fullDate.productName,
                    description: '!!${fullDate.fullDates.join(',')}')
              ])); // space
            }

            reservations.add(FinDoc(
                items: [FinDocItem(assetId: '', assetName: '')])); // space

            // group all open reservations by Room number as a single item
            assets.sort(
                (a, b) => (a.assetName ?? '?').compareTo(b.assetName ?? '?'));
            for (var asset in assets) {
              bool hasReservation = false;
              for (var finDoc in finDocs) {
                if (finDoc.status == FinDocStatusVal.created ||
                    finDoc.status == FinDocStatusVal.approved) {
                  // create a findoc for every item
                  for (var item in finDoc.items) {
                    if (item.assetId == asset.assetId &&
                        item.rentalFromDate != null &&
                        item.rentalThruDate != null) {
                      reservations.add(finDoc.copyWith(items: [item]));
                      hasReservation = true;
                    }
                  }
                }
              }
              if (!hasReservation) {
                reservations.add(FinDoc(items: [
                  FinDocItem(assetId: asset.assetId, assetName: asset.assetName)
                ]));
              }
            }
            var (leftColumn, rightColumn) = buildLeftRightColumn(
                context, screenWidth, reservations, finDocs);
            return Row(children: [
              Column(children: leftColumn),
              Expanded(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                          height: 1000,
                          width: 5000,
                          child: Stack(children: [
                            buildGrid(screenWidth),
                            buildHeader(screenWidth),
                            Column(children: rightColumn)
                          ]))))
            ]);
          }
          return const Center(child: CircularProgressIndicator());
        });
      });
    });
  }
}
