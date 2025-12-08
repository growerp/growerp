/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

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
  };
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
