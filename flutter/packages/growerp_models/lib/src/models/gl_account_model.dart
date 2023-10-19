/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import '../create_csv_row.dart';
import 'models.dart';
part 'gl_account_model.freezed.dart';
part 'gl_account_model.g.dart';

@freezed
class GlAccount with _$GlAccount {
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
      _$GlAccountFromJson(json);
}

String glAccountCsvFormat =
    'Account Code*, Account Name*, Class Description*, Type Description,'
    ' Posted Balance\r\n';
int glAccountCsvLength = glAccountCsvFormat.split(',').length;

List<GlAccount> CsvToGlAccounts(String csvFile) {
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
          postedBalance: row[4] != '' ? Decimal.parse(row[4]) : null),
    );
  }

  return glAccounts;
}

String CsvFromGlAccounts(List<GlAccount> glAccounts) {
  var csv = [glAccountCsvFormat];
  for (GlAccount glAccount in glAccounts) {
    csv.add(createCsvRow([
      glAccount.accountCode ?? '',
      glAccount.accountName ?? '',
      glAccount.accountClass!.description ?? '',
      glAccount.accountType!.description ?? '',
      glAccount.postedBalance == null ? '' : glAccount.postedBalance.toString(),
    ], glAccountCsvLength));
  }
  return csv.join();
}
