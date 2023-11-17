/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'marketing_test_model.dart';
import 'persist_marketing_test.dart';

class OpportunityTest {
  static Future<void> selectOpportunities(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbCrm', 'OpportunityListForm');
  }

  static Future<void> addOpportunities(
      WidgetTester tester, List<Opportunity> opportunities,
      {bool check = true}) async {
    MarketingTest test = await PersistMarketingTest.get();
    test = test.copyWith(opportunities: []); // delete just for test only-------
    if (test.opportunities.isEmpty) {
      // not yet created
      await enterOpportunityData(tester, opportunities);
      await PersistMarketingTest.save(
          test.copyWith(opportunities: opportunities));
    }
    if (check) {
      await PersistMarketingTest.save(test.copyWith(
          opportunities: await checkOpportunity(tester, opportunities)));
    }
  }

  static Future<void> updateOpportunities(
      WidgetTester tester, List<Opportunity> opportunities) async {
    MarketingTest test = await PersistMarketingTest.get();
    // check if already modified then skip
    var newOpportunities = List.of(test.opportunities);
    if (newOpportunities[0].opportunityName !=
        opportunities[0].opportunityName) {
      // get new opportunities preserving id
      for (int x = 0; x < test.opportunities.length; x++) {
        newOpportunities[x] = opportunities[x]
            .copyWith(opportunityId: test.opportunities[x].opportunityId);
      }
      await enterOpportunityData(tester, newOpportunities);
      await PersistMarketingTest.save(
          test.copyWith(opportunities: newOpportunities));
    }
    await checkOpportunity(tester, newOpportunities);
  }

  static Future<void> deleteLastOpportunity(WidgetTester tester) async {
    MarketingTest test = await PersistMarketingTest.get();
    var count = CommonTest.getWidgetCountByKey(tester, 'opportunityItem');
    if (count == test.opportunities.length) {
      await CommonTest.gotoMainMenu(tester);
      await OpportunityTest.selectOpportunities(tester);
      await CommonTest.tapByKey(tester, 'delete${count - 1}', seconds: 5);
      await CommonTest.gotoMainMenu(tester);
      await OpportunityTest.selectOpportunities(tester);
      expect(
          find.byKey(const Key('opportunityItem')), findsNWidgets(count - 1));
      await PersistMarketingTest.save(test.copyWith(
          opportunities:
              test.opportunities.sublist(0, test.opportunities.length - 1)));
    }
  }

  static Future<void> enterOpportunityData(
      WidgetTester tester, List<Opportunity> opportunities) async {
    for (Opportunity opportunity in opportunities) {
      if (opportunity.opportunityId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester,
            searchString: opportunity.opportunityId);
        await CommonTest.tapByKey(tester, 'name0');
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            opportunity.opportunityId);
      }
      await CommonTest.checkWidgetKey(tester, 'OpportunityDialog');
      await CommonTest.enterText(tester, 'name', opportunity.opportunityName!);
      await CommonTest.enterText(
          tester, 'description', opportunity.description!);
      await CommonTest.enterText(
          tester, 'estAmount', opportunity.estAmount.toString());
      await CommonTest.enterText(
          tester, 'estProbability', opportunity.estProbability.toString());
      await CommonTest.enterText(tester, 'nextStep', opportunity.nextStep!);
      await CommonTest.drag(tester, seconds: 1);
      await CommonTest.enterDropDown(tester, 'stageId', opportunity.stageId!);
      await CommonTest.enterDropDownSearch(
          tester, 'lead', opportunity.leadUser!.firstName!,
          seconds: 3);
      await CommonTest.enterDropDownSearch(
          tester, 'employee', opportunity.employeeUser!.firstName!,
          seconds: 3);
      await CommonTest.drag(tester, seconds: 1);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Opportunity>> checkOpportunity(
      WidgetTester tester, List<Opportunity> opportunities) async {
    List<Opportunity> newOpportunities = [];
    for (Opportunity opportunity in opportunities) {
      await CommonTest.doSearch(tester,
          searchString: opportunity.opportunityName!);
      expect(CommonTest.getTextField('name0'),
          equals(opportunity.opportunityName));
      expect(
          CommonTest.getTextField('lead0'),
          contains("${opportunity.leadUser!.firstName!} "
              "${opportunity.leadUser!.lastName!}"));
      if (!CommonTest.isPhone()) {
        expect(CommonTest.getTextField('estAmount0'),
            equals(opportunity.estAmount.toString()));
        expect(CommonTest.getTextField('estProbability0'),
            equals(opportunity.estProbability.toString()));
        expect(
            CommonTest.getTextField('stageId0'), equals(opportunity.stageId));
      }
      await CommonTest.tapByKey(tester, 'name0');
      expect(find.byKey(const Key('OpportunityDialog')), findsOneWidget);
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      expect(CommonTest.getTextFormField('name'),
          equals(opportunity.opportunityName!));
      expect(CommonTest.getTextFormField('description'),
          equals(opportunity.description!));
      expect(CommonTest.getTextFormField('estAmount'),
          equals(opportunity.estAmount.toString()));
      expect(CommonTest.getTextFormField('estProbability'),
          equals(opportunity.estProbability.toString()));
      expect(CommonTest.getDropdown('stageId'), contains(opportunity.stageId));
      expect(CommonTest.getDropdownSearch('lead'),
          contains(opportunity.leadUser!.company!.name!));
      expect(CommonTest.getDropdownSearch('employee'),
          contains(opportunity.employeeUser!.company!.name!));
      newOpportunities.add(opportunity.copyWith(opportunityId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return newOpportunities;
  }
}
