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
import 'package:growerp_models/growerp_models.dart';

/// Hours per assistant: in process (not yet approved), approved (billable)
/// and invoiced. Admins see all assistants; assistants only their own hours.
class TimeEntryReportList extends StatefulWidget {
  const TimeEntryReportList({super.key});

  @override
  TimeEntryReportListState createState() => TimeEntryReportListState();
}

class TimeEntryReportListState extends State<TimeEntryReportList> {
  late Future<TimeEntryReport> _report;

  @override
  void initState() {
    super.initState();
    _report = context.read<RestClient>().getTimeEntryReport();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TimeEntryReport>(
      future: _report,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Error getting hours report: ${snapshot.error}"),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!.reportItems;
        if (items.isEmpty) {
          return const Center(
            child: Text("No hours found", key: Key('empty')),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _report = context.read<RestClient>().getTimeEntryReport();
            });
          },
          child: ListView(
            key: const Key('timeEntryReport'),
            children: [
              const ListTile(
                title: Row(
                  children: [
                    Expanded(flex: 2, child: Text("Assistant")),
                    Expanded(
                      child: Text("In process", textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text("Approved", textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text("Invoiced", textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
              const Divider(),
              for (final (index, item) in items.indexed)
                ListTile(
                  key: Key('reportItem$index'),
                  title: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${item.firstName ?? ''} ${item.lastName ?? ''}",
                          key: Key('reportName$index'),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.inProcessHours?.toString() ?? '0',
                          key: Key('inProcessHours$index'),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.approvedHours?.toString() ?? '0',
                          key: Key('approvedHours$index'),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.invoicedHours?.toString() ?? '0',
                          key: Key('invoicedHours$index'),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
