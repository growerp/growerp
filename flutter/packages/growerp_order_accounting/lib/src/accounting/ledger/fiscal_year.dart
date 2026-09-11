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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Name of the fiscal year we are in now, like Y2026.
/// The accounting year can start in any month, so in the months before its
/// start month the current fiscal year is named after the previous calendar year.
String currentFiscalYearName(BuildContext context) =>
    'Y${currentFiscalYear(context)}';

/// Year the fiscal year we are in now is named after.
int currentFiscalYear(BuildContext context) {
  final now = DateTime.now();
  return now.month < fiscalYearStartMonth(context) ? now.year - 1 : now.year;
}

/// Month the accounting year of the logged in company starts: any month 1..12.
int fiscalYearStartMonth(BuildContext context) =>
    context
        .read<AuthBloc>()
        .state
        .authenticate
        ?.company
        ?.fiscalYearStartMonth ??
    1;

/// Year part of a period name: Y2025, Y2025q1 and Y2025m01 all give 2025.
int yearFromPeriodName(String periodName) =>
    int.tryParse(
      periodName.length >= 5 ? periodName.substring(1, 5) : periodName,
    ) ??
    DateTime.now().year;

/// The same period name shifted to another [year]: Y2025q1 -> Y2026q1.
String periodNameForYear(String periodName, int year) =>
    'Y$year${periodName.length > 5 ? periodName.substring(5) : ''}';

/// Whether [timePeriods] hold any period of [year].
bool periodYearExists(List<TimePeriod> timePeriods, int year) =>
    timePeriods.any((period) => period.periodName.startsWith('Y$year'));
