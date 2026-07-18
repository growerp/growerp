/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_activity.dart';

/// Returns widget mappings for the activity package
Map<String, GrowerpWidgetBuilder> getActivityWidgets() {
  return {
    'ActivityList': (args) => ActivityList(
      _parseActivityType(args?['activityType']),
      key: getKeyFromArgs(args),
    ),
    'TimeEntryReportList': (args) =>
        TimeEntryReportList(key: getKeyFromArgs(args)),
  };
}

/// Returns widget metadata with icons for the activity package
List<WidgetMetadata> getActivityWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'ActivityList',
      description: 'List of activities and tasks',
      iconName: 'task',
      keywords: ['activity', 'task', 'todo', 'action', 'event'],
      builder: (args) => ActivityList(
        _parseActivityType(args?['activityType']),
        key: getKeyFromArgs(args),
      ),
    ),
    WidgetMetadata(
      widgetName: 'TimeEntryReportList',
      description: 'Hours per assistant: in process, approved and invoiced',
      iconName: 'schedule',
      keywords: ['hours', 'time', 'report', 'assistant', 'timesheet'],
      builder: (args) => TimeEntryReportList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'ActivityDialog',
      description: 'Create or edit an activity/task. Pass activityId to edit an '
          'existing activity; omit it to create a new one.',
      iconName: 'task',
      keywords: ['add activity', 'new activity', 'create task', 'add task', 'edit activity'],
      parameters: {'activityId': 'open this activity for editing; omit to create new'},
      builder: (args) {
        final id = (args?['activityId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) {
          return ActivityDialog(Activity(), null);
        }
        return AsyncRecordDialog<Activity>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getActivity(activityId: id, limit: 1);
            return r.activities.isNotEmpty ? r.activities.first : null;
          },
          onLoaded: (a) => ActivityDialog(a, null),
        );
      },
    ),
  ];
}

ActivityType _parseActivityType(String? typeName) {
  if (typeName == null) return ActivityType.todo;
  try {
    return ActivityType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeName.toLowerCase(),
      orElse: () => ActivityType.todo,
    );
  } catch (_) {
    return ActivityType.todo;
  }
}
