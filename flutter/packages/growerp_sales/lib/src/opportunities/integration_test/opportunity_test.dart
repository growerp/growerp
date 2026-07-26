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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'marketing_test_model.dart';
import 'persist_marketing_test.dart';

class OpportunityTest {
  static Future<void> selectOpportunities(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbCrm', 'OpportunityList');
  }

  static Future<void> addOpportunities(
    WidgetTester tester,
    List<Opportunity> opportunities, {
    bool check = true,
  }) async {
    MarketingTest test = await PersistMarketingTest.get();
    if (test.opportunities.isEmpty) {
      // not yet created
      await enterOpportunityData(tester, opportunities);
      await PersistMarketingTest.save(
        test.copyWith(opportunities: opportunities),
      );
    }
    if (check) {
      await PersistMarketingTest.save(
        test.copyWith(
          opportunities: await checkOpportunity(tester, opportunities),
        ),
      );
    }
  }

  static Future<void> updateOpportunities(
    WidgetTester tester,
    List<Opportunity> opportunities,
  ) async {
    MarketingTest test = await PersistMarketingTest.get();
    // check if already modified then skip
    var newOpportunities = List.of(test.opportunities);
    if (newOpportunities[0].opportunityName !=
        opportunities[0].opportunityName) {
      // get new opportunities preserving id
      for (int x = 0; x < test.opportunities.length; x++) {
        newOpportunities[x] = opportunities[x].copyWith(
          opportunityId: test.opportunities[x].opportunityId,
        );
      }
      await enterOpportunityData(tester, newOpportunities);
      await PersistMarketingTest.save(
        test.copyWith(opportunities: newOpportunities),
      );
    }
    await checkOpportunity(tester, newOpportunities);
  }

  static Future<void> deleteOpportunities(WidgetTester tester) async {
    MarketingTest test = await PersistMarketingTest.get();
    var count = CommonTest.getWidgetCountByKey(tester, 'opportunityItem');
    if (count == test.opportunities.length) {
      await CommonTest.tapByKey(
        tester,
        'delete${count - 1}',
        seconds: CommonTest.waitTime,
      );
      expect(
        find.byKey(const Key('opportunityItem')),
        findsNWidgets(count - 1),
      );
      await PersistMarketingTest.save(
        test.copyWith(
          opportunities: test.opportunities.sublist(
            0,
            test.opportunities.length - 1,
          ),
        ),
      );
    }
  }

  static Future<void> enterOpportunityData(
    WidgetTester tester,
    List<Opportunity> opportunities,
  ) async {
    for (Opportunity opportunity in opportunities) {
      if (opportunity.opportunityId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(
          tester,
          searchString: opportunity.opportunityId,
        );
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          opportunity.opportunityId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'OpportunityDialog');
      await CommonTest.enterText(tester, 'name', opportunity.opportunityName!);
      await CommonTest.enterText(
        tester,
        'description',
        opportunity.description!,
      );
      await CommonTest.enterText(
        tester,
        'estAmount',
        opportunity.estAmount.toString(),
      );
      await CommonTest.enterText(
        tester,
        'estProbability',
        opportunity.estProbability.toString(),
      );
      await CommonTest.enterText(tester, 'nextStep', opportunity.nextStep!);
      await CommonTest.drag(tester, seconds: 1);
      await CommonTest.enterDropDown(tester, 'stageId', opportunity.stageId!);
      await CommonTest.enterDropDownSearch(
        tester,
        'lead',
        opportunity.leadUser!.firstName!,
        seconds: CommonTest.waitTime,
      );
      await CommonTest.enterDropDownSearch(
        tester,
        'employee',
        opportunity.employeeUser!.firstName!,
        seconds: CommonTest.waitTime,
      );
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Opportunity>> checkOpportunity(
    WidgetTester tester,
    List<Opportunity> opportunities,
  ) async {
    List<Opportunity> newOpportunities = [];
    for (final opportunity in opportunities) {
      /* list checking to be added
      expect(CommonTest.getTextField('name$index'),
          equals(opportunity.opportunityName));
      if (!CommonTest.isPhone()) {
        expect(
            CommonTest.getTextField('lead$index'),
            contains("${opportunity.leadUser!.firstName!} "
                "${opportunity.leadUser!.lastName!}"));
        expect(CommonTest.getTextField('estAmount$index'),
            equals(opportunity.estAmount.toString()));
        expect(CommonTest.getTextField('estProbability$index'),
            equals(opportunity.estProbability.toString()));
        expect(CommonTest.getTextField('stageId$index'),
            equals(opportunity.stageId));
      }*/
      await CommonTest.doNewSearch(
        tester,
        searchString: opportunity.opportunityName!,
      );
      expect(find.byKey(const Key('OpportunityDialog')), findsOneWidget);
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      expect(
        CommonTest.getTextFormField('name'),
        equals(opportunity.opportunityName!),
      );
      expect(
        CommonTest.getTextFormField('description'),
        equals(opportunity.description!),
      );
      expect(
        CommonTest.getTextFormField('estAmount'),
        equals(opportunity.estAmount.toString()),
      );
      expect(
        CommonTest.getTextFormField('estProbability'),
        equals(opportunity.estProbability.toString()),
      );
      expect(CommonTest.getDropdown('stageId'), contains(opportunity.stageId));
      expect(
        CommonTest.getDropdownSearch('lead'),
        contains(opportunity.leadUser!.company!.name!),
      );
      expect(
        CommonTest.getDropdownSearch('employee'),
        contains(opportunity.employeeUser!.company!.name!),
      );
      newOpportunities.add(opportunity.copyWith(opportunityId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    return newOpportunities;
  }
}
