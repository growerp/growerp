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

import 'package:freezed_annotation/freezed_annotation.dart';
part 'glAccount_model.freezed.dart';
part 'glAccount_model.g.dart';

@freezed
class GlAccount with _$GlAccount {
  GlAccount._();
  factory GlAccount({
    String? id,
    int? l,
    String? classId,
    String? isDebit,
    String? accountName,
    double? postedBalance,
    double? rollUp,
    @Default([]) List<GlAccount> children,
  }) = _GlAccount;

  factory GlAccount.fromJson(Map<String, dynamic> json) =>
      _$GlAccountFromJson(json);
}
