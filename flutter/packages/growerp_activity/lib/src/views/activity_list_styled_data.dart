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
import '../blocs/activity_bloc.dart';
import 'package:growerp_activity/l10n/generated/activity_localizations.dart';

List<StyledColumn> getActivityListColumns(
  BuildContext context,
  ActivityType activityType,
) {
  final localizations = ActivityLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  return [
    StyledColumn(header: localizations.activity_id, flex: isPhone ? 2 : 1),
    StyledColumn(header: localizations.activity_name, flex: isPhone ? 4 : 3),
    if (!isPhone && activityType == ActivityType.todo)
      StyledColumn(header: localizations.activity_tableHdrAssignee, flex: 2),
    if (!isPhone)
      StyledColumn(header: localizations.activity_tableHdrThirdParty, flex: 2),
    if (activityType == ActivityType.todo)
      StyledColumn(header: localizations.activity_status, flex: 2),
    if (activityType == ActivityType.todo)
      StyledColumn(header: localizations.activity_tableHdrEstFrom, flex: 2),
    if (!isPhone)
      StyledColumn(header: localizations.activity_tableHdrActFrom, flex: 2),
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
        [
          activity.originator?.firstName,
          activity.originator?.lastName,
        ].where((s) => s != null && s.isNotEmpty).join(' '),
        key: Key('assignee$index'),
      ),
    if (!isPhone)
      Text(
        [
          activity.thirdParty?.firstName,
          activity.thirdParty?.lastName,
        ].where((s) => s != null && s.isNotEmpty).join(' '),
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
