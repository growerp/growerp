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

import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../growerp_activity.dart';

class TimeEntryListItem extends StatelessWidget {
  const TimeEntryListItem({
    super.key,
    required this.activityId,
    required this.timeEntry,
    required this.index,
  });

  final String activityId;
  final TimeEntry timeEntry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.read<AuthBloc>().state.authenticate?.user?.userGroup ==
        UserGroup.admin;
    final isInvoiced =
        timeEntry.invoiceId != null || timeEntry.vendorInvoiceId != null;
    final status = isInvoiced ? 'invoiced' : (timeEntry.status ?? 'inProcess');
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              timeEntry.date != null
                  ? "${timeEntry.date!.toLocal()}".split(' ')[0]
                  : '',
              key: Key('date$index'),
            ),
          ),
          Text("${timeEntry.hours}", key: Key('hours$index')),
          Expanded(
            child: Text(
              status,
              key: Key('status$index'),
              textAlign: TextAlign.center,
            ),
          ),
          if (!isPhone(context))
            Expanded(
              child: Text(
                "${timeEntry.partyId}",
                key: Key('partyId$index'),
                textAlign: TextAlign.center,
              ),
            ),
          if (!isPhone(context))
            Expanded(
              child: Text(
                "${timeEntry.comments}",
                key: Key('comments$index'),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      onTap: isInvoiced
          ? null
          : () async {
              await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return BlocProvider.value(
                    value: context.read<ActivityBloc>(),
                    child: TimeEntryDialog(timeEntry),
                  );
                },
              );
            },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAdmin && !isInvoiced && status == 'inProcess')
            IconButton(
              key: Key('approve$index'),
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Approve',
              padding: EdgeInsets.zero,
              onPressed: () {
                context.read<ActivityBloc>().add(
                  ActivityTimeEntryUpdate(
                    timeEntry.copyWith(status: 'approved'),
                  ),
                );
              },
            ),
          if (!isInvoiced)
            IconButton(
              key: Key('delete$index'),
              icon: const Icon(Icons.delete_forever),
              padding: EdgeInsets.zero,
              onPressed: () {
                context.read<ActivityBloc>().add(
                  ActivityTimeEntryDelete(timeEntry),
                );
              },
            ),
        ],
      ),
    );
  }
}
