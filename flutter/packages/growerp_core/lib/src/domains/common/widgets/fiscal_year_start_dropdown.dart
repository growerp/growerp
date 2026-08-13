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
import 'package:intl/intl.dart';

/// The accounting year starts on the first day of any month.
const List<int> fiscalYearStartMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

/// Select the month the accounting year starts in: any month of the year, its
/// quarters then run in three month blocks from there.
/// Pass a null [onChanged] to show the current value read only, which is needed
/// when transactions have been posted.
class FiscalYearStartDropdown extends StatelessWidget {
  final int? value;
  final String label;
  final String? helperText;
  final ValueChanged<int?>? onChanged;

  const FiscalYearStartDropdown({
    super.key,
    required this.value,
    required this.label,
    this.helperText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DropdownButtonFormField<int>(
      key: const Key('fiscalYearStart'),
      initialValue: fiscalYearStartMonths.contains(value) ? value : 1,
      decoration: InputDecoration(labelText: label, helperText: helperText),
      onChanged: onChanged,
      items: [
        for (final month in fiscalYearStartMonths)
          DropdownMenuItem(
            key: Key('fiscalYearStart$month'),
            value: month,
            child: Text(
              '1 ${DateFormat.MMMM(locale).format(DateTime(2000, month))}',
            ),
          ),
      ],
    );
  }
}
