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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_hr.dart';

List<StyledColumn> getLeaveRequestListColumns(
  BuildContext context, {
  required bool myRequests,
}) {
  final localizations = HrLocalizations.of(context)!;
  if (isAPhone(context)) {
    return [StyledColumn(header: localizations.leaveRequests, flex: 6)];
  }
  return [
    const StyledColumn(header: 'Id', flex: 2),
    if (!myRequests) StyledColumn(header: localizations.employee, flex: 3),
    StyledColumn(header: localizations.leaveType, flex: 2),
    StyledColumn(header: localizations.fromDate, flex: 2),
    StyledColumn(header: localizations.days, flex: 1),
    StyledColumn(header: localizations.status, flex: 2),
  ];
}

List<Widget> getLeaveRequestListRow({
  required BuildContext context,
  required LeaveRequest leaveRequest,
  required int index,
  required bool myRequests,
}) {
  final cells = <Widget>[];
  final fromDate = leaveRequest.fromDate?.toLocalizedDateOnly(context) ?? '';
  if (isAPhone(context)) {
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                leaveRequest.pseudoId,
                key: Key('id$index'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Text(' '),
              if (!myRequests)
                Flexible(
                  child: Text(
                    leaveRequest.employeeName ?? '',
                    key: Key('employee$index'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: Row(
              children: [
                Text(
                  leaveRequest.leaveType?.name ?? '',
                  key: Key('leaveType$index'),
                ),
                const Text(' '),
                Text(fromDate, key: Key('fromDate$index')),
                const Text(' '),
                Text(
                  leaveRequest.days?.toString() ?? '',
                  key: Key('days$index'),
                ),
                const Text(' '),
                Text(leaveRequest.status?.name ?? '', key: Key('status$index')),
              ],
            ),
          ),
        ],
      ),
    );
  } else {
    cells.add(
      SizedBox(
        key: Key('item$index'),
        child: Text(leaveRequest.pseudoId, key: Key('id$index')),
      ),
    );
    if (!myRequests) {
      cells.add(
        Text(leaveRequest.employeeName ?? '', key: Key('employee$index')),
      );
    }
    cells.add(
      Text(leaveRequest.leaveType?.name ?? '', key: Key('leaveType$index')),
    );
    cells.add(Text(fromDate, key: Key('fromDate$index')));
    cells.add(
      Text(leaveRequest.days?.toString() ?? '', key: Key('days$index')),
    );
    cells.add(Text(leaveRequest.status?.name ?? '', key: Key('status$index')));
  }
  return cells;
}
