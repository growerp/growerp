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
import 'package:core/domains/domains.dart';
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
    @Default([]) List<User> employees,
    @Default([]) List<User> leads,
    @Default([]) List<User> suppliers,
    @Default([]) List<User> customers,
    @Default([]) List<Category> categories,
    @Default([]) List<Product> products,
    @Default([]) List<Asset> assets,
    @Default([]) List<Location> locations,
    @Default([]) List<Opportunity> opportunities,
    @Default([]) List<Task> tasks,
    @Default([]) List<FinDoc> orders,
    @Default([]) List<FinDoc> payments,
    @Default([]) List<FinDoc> invoices,
    @Default([]) List<ChatRoom> chatRooms,
  }) = _MarketingTest;
  MarketingTest._();

  factory MarketingTest.fromJson(Map<String, dynamic> json) =>
      _$MarketingTestFromJson(json);
}
