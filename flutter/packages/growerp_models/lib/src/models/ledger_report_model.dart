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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

import 'models.dart';

part 'ledger_report_model.freezed.dart';
part 'ledger_report_model.g.dart';

@freezed
abstract class LedgerReport with _$LedgerReport {
  LedgerReport._();
  factory LedgerReport({
    Company? company,
    @Default('') String title,
    TimePeriod? period,
    DateTime? printDate,
    @Default([]) List<GlAccount> glAccounts,
    List<List<String>>? csvRows,
  }) = _LedgerReport;

  factory LedgerReport.fromJson(Map<String, dynamic> json) =>
      _$LedgerReportFromJson(json['ledgerReport'] ?? json);
}
