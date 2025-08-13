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
import 'models.dart';

part 'save_test_model.freezed.dart';
part 'save_test_model.g.dart';

@freezed
abstract class SaveTest with _$SaveTest {
  factory SaveTest({
    @Default(false) bool testDataLoaded,
    @Default(0) int sequence,
    Company? company,
    User? admin,
    DateTime? nowDate,
    @Default([]) List<Company> companies,
    @Default([]) List<CompanyUser> companiesUsers,
    @Default([]) List<User> users,
    @Default([]) List<Location> locations,
    @Default([]) List<Activity> activities,
    @Default([]) List<FinDoc> orders,
    @Default([]) List<FinDoc> payments,
    @Default([]) List<FinDoc> invoices,
    @Default([]) List<FinDoc> shipments,
    @Default([]) List<FinDoc> transactions,
    @Default([]) List<FinDoc> requests,
    @Default([]) List<ChatRoom> chatRooms,
    @Default([]) List<Asset> assets,
    @Default([]) List<Product> products,
    @Default([]) List<Category> categories,
    @Default([]) List<GlAccount> glAccounts,
    @Default([]) List<LedgerJournal> ledgerJournals,
    @Default([]) List<ItemType> itemTypes,
    @Default([]) List<PaymentType> paymentTypes,
    @Default([]) List<Subscription> subscriptions,
  }) = _SaveTest;
  SaveTest._();

  factory SaveTest.fromJson(Map<String, dynamic> json) =>
      _$SaveTestFromJson(json);
}
