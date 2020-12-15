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
import 'package:date_utils/date_utils.dart';
import '../data/reservation.dart';
import 'package:intl/intl.dart';

const DAY = 1, WEEK = 2, MONTH = 3; // columnPeriod values

int chartInDays;
int chartColumns; // total columns on chart
int columnsOnScreen; // periods plus room column

class GanttForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new GanttFormState();
  }
}

class GanttFormState extends State<GanttForm> {
  DateTime ganttFromDate;
  int columnPeriod; //DAY,  WEEK, MONTH
  List<Room> roomsInChart;
  List<Reservation> reservations;

  @override
  void initState() {
    super.initState();
    columnPeriod = DAY;
    reservations = reservationsInput;
    roomsInChart = rooms;
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    DateTime now = DateTime.now();
    DateTime nowDate = DateTime(now.year, now.month, now.day, 14, 0, 0, 0);
    switch (columnPeriod) {
      case MONTH:
        if (screenWidth < 800) {
          columnsOnScreen = 4;
        } else {
          columnsOnScreen = 8;
        }
        chartColumns = 13;
        chartInDays = 365;
        ganttFromDate = DateTime(now.year, now.month, 1, 14, 0, 0, 0);
        break;
      case WEEK:
        if (screenWidth < 800) {
          chartColumns = 14;
          columnsOnScreen = 4;
        } else {
          chartColumns = 21;
          columnsOnScreen = 8;
        }
        chartInDays = (chartColumns) * 7;
        ganttFromDate = nowDate.subtract(Duration(days: nowDate.weekday));
        break;
      case DAY:
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
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RaisedButton(
                  onPressed: () => setState(() => columnPeriod = DAY),
                  child: Text('Day'),
                ),
                RaisedButton(
                  onPressed: () => setState(() => columnPeriod = WEEK),
                  child: Text('Week'),
                ),
                RaisedButton(
                  onPressed: () => setState(() => columnPeriod = MONTH),
                  child: Text('Month'),
                ),
                SizedBox(width: 30),
              ],
            ),
          ),
          SizedBox(height: 5),
          Expanded(
            child: GanttChart(
              columnPeriod: columnPeriod,
              ganttFromDate: ganttFromDate,
              reservations: reservations,
              roomsInChart: roomsInChart,
            ),
          ),
        ],
      ),
    );
  }
}

class GanttChart extends StatelessWidget {
  final int columnPeriod;
  final DateTime ganttFromDate;
  final List<Reservation> reservations;
  final List<Room> roomsInChart;

  GanttChart({
    this.columnPeriod,
    this.ganttFromDate,
    this.reservations,
    this.roomsInChart,
  });

  @override
  Widget build(BuildContext context) {
    // sort by roomId and fromDate
    reservations.sort((a, b) {
      var r = a.roomId.compareTo(b.roomId);
      if (r != 0) return r;
      return a.fromDate.compareTo(b.fromDate);
    });
    //reservations.forEach((e) => print(
    //    "id: ${e.id} from ${e.fromDate.toString()} to: ${e.thruDate.toString()}"));
    var screenWidth = MediaQuery.of(context).size.width;

    var chartBars = buildChartBars(screenWidth);
    return Container(
      height: chartBars.length * 29.0 + 25.0 + 4.0,
      child: ListView(
        physics: new ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Stack(fit: StackFit.loose, children: <Widget>[
            buildGrid(screenWidth),
            buildHeader(screenWidth, Colors.lightGreen),
            Container(
                margin: EdgeInsets.only(top: 25.0),
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: chartBars,
                        ),
                      ),
                    ],
                  ),
                )),
          ]),
        ],
      ),
    );
  }

  Widget buildGrid(double screenWidth) {
    List<Widget> gridColumns = new List();

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
    List<Widget> headerItems = new List();

    DateTime tempDate = ganttFromDate;

    headerItems.add(Container(
      width: screenWidth / columnsOnScreen,
      child: new Text(
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
    String headerText;
    int year = ganttFromDate.year;
    for (int i = 0; i < chartColumns; i++) {
      if (columnPeriod == MONTH) {
        headerText =
            months[(ganttFromDate.month + i - 1) % 12] + ' ' + year.toString();
        if ((ganttFromDate.month + i) == 12) year++;
      }
      var formatter = new DateFormat('yyyy-MM-dd');
      if (columnPeriod == WEEK) {
        headerText = 'Week starting: ' +
            days[(ganttFromDate.weekday) % 7] +
            '\n' +
            formatter.format(ganttFromDate.add(new Duration(days: i * 7)));
      }
      if (columnPeriod == DAY) {
        headerText = days[(ganttFromDate.weekday - 1 + i) % 7] +
            '\n' +
            formatter.format(ganttFromDate.add(new Duration(days: i)));
      }
      headerItems.add(Container(
        width: screenWidth / columnsOnScreen,
        child: new Text(
          headerText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.0,
          ),
        ),
      ));
      tempDate = Utils.nextMonth(tempDate);
    }

    return Container(
      height: 25.0,
      color: color.withAlpha(100),
      child: Row(
        children: headerItems,
      ),
    );
  }

  List<Widget> buildChartBars(double screenWidth) {
    List<Widget> chartBars = new List();
    var last;
    for (int i = 0; i < reservations.length; i++) {
      if (last != null && reservations[i].roomId == last.roomId)
        continue; // skip more than one reservation for a single room
      last = reservations[i];
      chartBars.add(Row(children: <Widget>[
        Container(
          height: 20,
          width: screenWidth / columnsOnScreen,
          child: Text(
            reservations[i].roomId.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        Row(children: buildReservations(i, screenWidth)),
      ]));
    }
    return chartBars;
  }

  List<Widget> buildReservations(int index, double screenWidth) {
    DateTime lastDate = ganttFromDate.subtract(Duration(days: 1));
    List<Widget> chartContent = new List();
    int currentRoomId = reservations[index].roomId;
    double halfDay, halfDayLength = 0;
    while (index < reservations.length &&
        reservations[index].roomId == currentRoomId) {
      // define the scale of 1 day
      double dayScale;
      if (columnPeriod == DAY) dayScale = screenWidth / columnsOnScreen;
      if (columnPeriod == WEEK) dayScale = screenWidth / (columnsOnScreen * 7);
      if (columnPeriod == MONTH)
        dayScale = screenWidth / (columnsOnScreen * 365 / 12);
      if (halfDay == null) halfDay = dayScale / 2;

      BorderRadius borderRadius = BorderRadius.circular(10.0);
      if (reservations[index].thruDate.isBefore(ganttFromDate)) {
        reservations.removeAt(index);
        continue;
      }
      if (reservations[index].fromDate.isBefore(ganttFromDate)) {
        reservations[index].fromDate = lastDate;
        borderRadius = BorderRadius.only(
            topRight: Radius.circular(10.0),
            bottomRight: Radius.circular(10.0));
        halfDay = 0;
        halfDayLength = dayScale / 2;
      }
      if (lastDate != null) {
        DateTime from = reservations[index].fromDate;
        DateTime thru = reservations[index].thruDate;
        //print(
        //    'i2: ${reservations[index].id} from: ${from.toString()} thru: ${thru.toString()}'
        //    'difference: ${thru.difference(from).inDays}');
        chartContent.add(Container(
          decoration:
              BoxDecoration(color: Colors.green, borderRadius: borderRadius),
          height: 20.0,
          width: (thru.difference(from).inDays) * dayScale + halfDayLength,
          margin: EdgeInsets.only(
              left: (reservations[index].fromDate.difference(lastDate).inDays) *
                      dayScale +
                  halfDay,
              top: 4.0,
              bottom: 4.0),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              reservations[index].customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.0),
            ),
          ),
        ));
      }
      lastDate = reservations[index].thruDate;
      index++;
      halfDay = 0.00;
    }
    return chartContent;
  }
}
