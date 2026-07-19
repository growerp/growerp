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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_adk/growerp_adk.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';

enum Period { day, week, month }

/// Date-range rental timeline: one row per rentable asset (hotel room, rental
/// equipment, ...) with a bar for every reservation over the period. Shared by
/// the hotel and rental verticals; the noun ("Room" vs "Equipment") follows the
/// hosting app's applicationId.
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
  late String _assetNoun; // 'Room' for hotel, 'Equipment' otherwise
  List<Asset> assets = [];
  List<FinDoc> finDocs = [];
  List<FinDoc> reservations = [];
  List<ProductRentalDate> productRentalDates = [];
  List<Widget> chartContent = [];
  int itemCount = 0;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchString = '';
  late double screenWidth;
  late ColorScheme scheme;
  late int chartInDays;
  late int chartColumns; // total columns on chart
  late int columnsOnScreen; // periods
  late double bottom;
  double? right;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    columnPeriod = Period.day;
    _salesOrderBloc = context.read<SalesOrderBloc>()..add(const FinDocFetch());
    _assetBloc = context.read<AssetBloc>()
      ..add(const AssetFetch(refresh: true));
    _finDocBloc = context.read<FinDocBloc>()
      ..add(const FinDocProductRentalDates(null));
    _assetNoun = context.read<String>() == 'AppHotel' ? 'Room' : 'Equipment';

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

                  // group all open reservations by asset as a single item
                  assets = List.of(assets);
                  final Set<String> matchingOrderIds = {};
                  if (_searchString.isNotEmpty) {
                    final searchLower = _searchString.toLowerCase();
                    final dateFormatter = DateFormat('yyyy-MM-dd');
                    final matchingAssetIds = <String>{};
                    for (var finDoc in finDocs) {
                      if (finDoc.status == FinDocStatusVal.created ||
                          finDoc.status == FinDocStatusVal.approved) {
                        for (var item in finDoc.items) {
                          final matches =
                              (finDoc.pseudoId ?? '')
                                  .toLowerCase()
                                  .contains(searchLower) ||
                              (finDoc.otherUser?.firstName ?? '')
                                  .toLowerCase()
                                  .contains(searchLower) ||
                              (finDoc.otherUser?.lastName ?? '')
                                  .toLowerCase()
                                  .contains(searchLower) ||
                              (finDoc.otherCompany?.name ?? '')
                                  .toLowerCase()
                                  .contains(searchLower) ||
                              (item.rentalFromDate != null &&
                                  dateFormatter
                                      .format(item.rentalFromDate!)
                                      .contains(searchLower));
                          if (matches && item.asset?.assetId != null) {
                            matchingAssetIds.add(item.asset!.assetId);
                            matchingOrderIds.add(finDoc.orderId ?? '');
                          }
                        }
                      }
                    }
                    assets = assets
                        .where((a) => matchingAssetIds.contains(a.assetId))
                        .toList();
                  }
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
                        if (_searchString.isNotEmpty &&
                            !matchingOrderIds.contains(finDoc.orderId ?? '')) {
                          continue;
                        }
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
                    if (!hasReservation && _searchString.isEmpty) {
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
                          if (!isAPhone(context))
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: GreetingHeader(
                                searchWidget: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (value) {
                                    setState(() => _searchString = value);
                                    if (value.length >= 3) {
                                      _salesOrderBloc.add(FinDocFetch(
                                        searchString: value,
                                        refresh: true,
                                      ));
                                    } else if (value.isEmpty) {
                                      _salesOrderBloc.add(
                                        const FinDocFetch(refresh: true),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search reservation ID, customer name, date...',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                    ),
                                    suffixIcon: _searchString.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 18,
                                            ),
                                            onPressed: () => setState(() {
                                              _searchController.clear();
                                              _searchString = '';
                                            }),
                                          )
                                        : null,
                                    filled: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (isAPhone(context))
                            ListFilterBar(
                              searchHint:
                                  'Search reservation ID, customer name, date...',
                              searchController: _searchController,
                              focusNode: _searchFocusNode,
                              onSearchChanged: (value) {
                                setState(() => _searchString = value);
                                if (value.length >= 3) {
                                  _salesOrderBloc.add(FinDocFetch(
                                    searchString: value,
                                    refresh: true,
                                  ));
                                } else if (value.isEmpty) {
                                  _salesOrderBloc.add(
                                    const FinDocFetch(refresh: true),
                                  );
                                }
                              },
                            ),
                          Expanded(
                            child: HorizontalDataTable(
                              leftHandSideColumnWidth: 96,
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
                              const SizedBox(height: 5),
                              FloatingActionButton(
                                heroTag: 'adkChatFab',
                                key: const Key('adkChatFab'),
                                onPressed: () => AdkChatDialog.show(context),
                                tooltip: 'AI Assistant',
                                child: const Icon(Icons.smart_toy),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (assetState.assets.isEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            const SizedBox(height: 200),
                            Center(
                              child: Text(
                                "No ${_assetNoun}s found,\n goto the "
                                "${_assetNoun.toLowerCase()} section to add:\n"
                                "1. ${_assetNoun.toLowerCase()} types\n"
                                "2. actual ${_assetNoun.toLowerCase()}s related "
                                "to ${_assetNoun.toLowerCase()} types",
                                style: const TextStyle(fontSize: 20.0),
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
    final headerDecoration = BoxDecoration(
      color: scheme.surfaceContainerHighest,
      border: Border(
        bottom: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
    );
    final headerTextStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.4,
    );
    List<Widget> headerItems = [
      Container(
        height: 48,
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: headerDecoration,
        alignment: Alignment.centerLeft,
        child: Text('$_assetNoun Type\nnbr/name', style: headerTextStyle),
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
            'Week:\n${days[(ganttFromDate.weekday) % 7]} ${formatter.format(ganttFromDate.add(Duration(days: i * 7)))}';
      }
      if (columnPeriod == Period.day) {
        headerText =
            '${days[(ganttFromDate.weekday + i) % 7]}\n${formatter.format(ganttFromDate.add(Duration(days: i)))}';
      }
      headerItems.add(
        Container(
          height: 48,
          decoration: headerDecoration,
          width: screenWidth / columnsOnScreen,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            headerText,
            textAlign: TextAlign.center,
            style: headerTextStyle,
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
      var assetReservation = reservations.firstWhere(
        (element) =>
            int.parse(element.shipmentId ?? '') ==
            index - productRentalDates.length,
      );
      columnText = assetReservation.items[0].asset?.assetName ?? '';
    }
    final isEven = index.isEven;
    return Container(
      width: 96,
      height: 20,
      padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isEven
            ? scheme.surface
            : scheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        columnText,
        style: TextStyle(
          fontSize: 11,
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// print single bar depending on the start and end rental dates for
  /// either by product (asset type) or asset
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
      // occupation by product
      if (reservation.items[0].rentalFromDate != null &&
          reservation.items[0].rentalThruDate!
                  .difference(ganttFromDate)
                  .inDays >=
              0) {
        // show occupation by asset ========================================
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
                  color: scheme.primary,
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
