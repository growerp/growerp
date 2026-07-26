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
    @Default([]) List<LandingPage> landingPages,
    @Default([]) List<Assessment> assessments,
    @Default([]) List<Persona> personas,
    @Default([]) List<ContentPlan> contentPlans,
    @Default([]) List<SocialPost> socialPosts,
    @Default([]) List<MasterContent> masterContents,
    @Default([]) List<OutreachCampaign> outreachCampaigns,
    @Default([]) List<MenuItem> menuItems,
    @Default([]) List<AdkAgentConfig> adkAgentConfigs,
    @Default([]) List<AdkKnowledgeDoc> adkKnowledgeDocs,
  }) = _SaveTest;
  SaveTest._();

  factory SaveTest.fromJson(Map<String, dynamic> json) =>
      _$SaveTestFromJson(json);
}
