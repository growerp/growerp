export 'package:growerp_models/testing.dart';

import 'dart:convert';

import 'package:growerp_models/growerp_models.dart';

/// getCourse / getCourseCatalog bodies arrive as JSON strings
/// (the Dio client uses ResponseType.plain).
String courseJson(Course course) => jsonEncode({'course': course.toJson()});
