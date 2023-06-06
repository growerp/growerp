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
import 'package:growerp_core/growerp_core.dart';
import '../models/opportunity_model.dart';

part 'marketing_test_model.freezed.dart';
part 'marketing_test_model.g.dart';

@freezed
class MarketingTest with _$MarketingTest {
  factory MarketingTest({
    @Default(0) int sequence,
    Company? company,
    User? admin,
    DateTime? nowDate,
    @Default([]) List<Company> companies,
    @Default([]) List<User> administrators,
    @Default([]) List<User> leads,
    @Default([]) List<Opportunity> opportunities,
  }) = _MarketingTest;
  MarketingTest._();

  factory MarketingTest.fromJson(Map<String, dynamic> json) =>
      _$MarketingTestFromJson(json);
}
