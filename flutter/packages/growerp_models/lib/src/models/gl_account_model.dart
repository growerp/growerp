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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import '../create_csv_row.dart';
import 'models.dart';
part 'gl_account_model.freezed.dart';
part 'gl_account_model.g.dart';

@freezed
abstract class GlAccount with _$GlAccount {
  GlAccount._();
  factory GlAccount({
    String? glAccountId,
    String? accountCode,
    String? accountName,
    int? level,
    AccountClass? accountClass,
    AccountType? accountType,
    bool? isDebit,
    Decimal? rollUp,
    Decimal? beginningBalance,
    Decimal? postedDebits,
    Decimal? postedCredits,
    Decimal? postedBalance,
    @Default([]) List<GlAccount> children,
  }) = _GlAccount;

  factory GlAccount.fromJson(Map<String, dynamic> json) =>
      _$GlAccountFromJson(json['glAccount'] ?? json);
}

String glAccountCsvFormat =
    'Account Code*, Account Name*, Class Description*, Type Description,'
    ' Posted Balance, itemType in, itemType out \r\n';
int glAccountCsvLength = glAccountCsvFormat.split(',').length;

// import
List<GlAccount> csvToGlAccounts(String csvFile) {
  List<GlAccount> glAccounts = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    glAccounts.add(
      GlAccount(
        accountCode: row[0],
        accountName: row[1],
        accountClass: row[2] != '' ? AccountClass(description: row[2]) : null,
        accountType: row[3] != '' ? AccountType(description: row[3]) : null,
        postedBalance: row[4] != '' ? Decimal.parse(row[4]) : null,
      ),
    );
  }
  return glAccounts;
}

// export
String csvFromGlAccounts(List<GlAccount> glAccounts) {
  var csv = [glAccountCsvFormat];
  for (GlAccount glAccount in glAccounts) {
    csv.add(
      createCsvRow([
        glAccount.accountCode ?? '',
        glAccount.accountName ?? '',
        glAccount.accountClass!.description ?? '',
        glAccount.accountType!.description ?? '',
        glAccount.postedBalance == null
            ? ''
            : glAccount.postedBalance.toString(),
      ], glAccountCsvLength),
    );
  }
  return csv.join();
}
