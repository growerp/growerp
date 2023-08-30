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
part 'gl_account_class_model.freezed.dart';
part 'gl_account_class_model.g.dart';

@freezed
class GlAccountClass with _$GlAccountClass {
  GlAccountClass._();
  factory GlAccountClass({
    String? glAccountClassId,
    String? parentClassId,
    String? description,
  }) = _GlAccountClass;

  factory GlAccountClass.fromJson(Map<String, dynamic> json) =>
      _$GlAccountClassFromJson(json);
}
