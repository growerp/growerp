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

import 'package:flutter/widgets.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';

/// The CourseBloc emits message keys; anything else (a backend error) is
/// shown as it is.
String translateCourseBlocMessage(BuildContext context, String message) {
  final l = CoursesLocalizations.of(context)!;
  return switch (message) {
    'courseCreated' => l.courses_courseCreated,
    'courseUpdated' => l.courses_courseUpdated,
    'courseDeleted' => l.courses_courseDeleted,
    'courseSubscribed' => l.courses_courseSubscribed,
    'courseIdRequired' => l.courses_courseIdRequired,
    _ => message,
  };
}
