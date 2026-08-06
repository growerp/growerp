/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_activity/l10n/generated/activity_localizations.dart';

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
            child: Text(ActivityLocalizations.of(context)!.activity_errorGettingHoursReport(snapshot.error.toString())),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!.reportItems;
        if (items.isEmpty) {
          return Center(
            child: Text(ActivityLocalizations.of(context)!.activity_noHoursFound, key: Key('empty')),
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
              ListTile(
                title: Row(
                  children: [
                    Expanded(flex: 2, child: Text("Assistant")),
                    Expanded(
                      child: Text(ActivityLocalizations.of(context)!.activity_inProcess, textAlign: TextAlign.right),
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
