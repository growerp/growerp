/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../blocs/activity_bloc.dart';

List<StyledColumn> getActivityListColumns(
  BuildContext context,
  ActivityType activityType,
) {
  bool isPhone = isAPhone(context);
  return [
    StyledColumn(header: 'ID', flex: isPhone ? 2 : 1),
    StyledColumn(header: 'Name', flex: isPhone ? 4 : 3),
    if (!isPhone && activityType == ActivityType.todo)
      const StyledColumn(header: 'Assignee', flex: 2),
    if (!isPhone) const StyledColumn(header: 'Third Party', flex: 2),
    if (activityType == ActivityType.todo)
      const StyledColumn(header: 'Status', flex: 2),
    if (activityType == ActivityType.todo)
      const StyledColumn(header: 'Est. From', flex: 2),
    if (!isPhone) const StyledColumn(header: 'Act. From', flex: 2),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getActivityListRow({
  required BuildContext context,
  required Activity activity,
  required int index,
  required ActivityBloc bloc,
}) {
  bool isPhone = isAPhone(context);
  return [
    Text(activity.pseudoId, key: Key('id$index')),
    Text(activity.activityName, key: Key('name$index')),
    if (!isPhone && activity.activityType == ActivityType.todo)
      Text(
        "${activity.originator?.firstName} ${activity.originator?.lastName}",
        key: Key('assignee$index'),
      ),
    if (!isPhone)
      Text(
        "${activity.thirdParty?.firstName} ${activity.thirdParty?.lastName}",
        key: Key('thirdParty$index'),
      ),
    if (activity.activityType == ActivityType.todo)
      Text("${activity.statusId}", key: Key('status$index')),
    if (activity.activityType == ActivityType.todo)
      Text(
        "${activity.estimatedStartDate != null ? activity.estimatedStartDate?.toLocal().toIso8601String().substring(0, 10) : ''}",
        key: Key('estFromDate$index'),
      ),
    if (!isPhone)
      Text(
        "${activity.actualStartDate != null ? activity.actualStartDate?.toLocal().toIso8601String().substring(0, 10) : ''}",
        key: Key('fromDate$index'),
      ),
    IconButton(
      key: Key('delete$index'),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.delete_forever),
      onPressed: () {
        bloc.add(
          ActivityUpdate(activity.copyWith(statusId: ActivityStatus.closed)),
        );
      },
    ),
  ];
}
