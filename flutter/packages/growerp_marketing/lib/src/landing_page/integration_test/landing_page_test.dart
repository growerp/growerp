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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class LandingPageTest {
  static Future<void> selectLandingPages(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/landingPages',
      'LandingPageList',
      null,
    );
  }

  static Future<void> addLandingPages(
    WidgetTester tester,
    List<LandingPage> landingPages,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
        test.copyWith(landingPages: landingPages));
    await enterLandingPageData(tester);
  }

  static Future<void> updateLandingPages(
    WidgetTester tester,
    List<LandingPage> newLandingPages,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy IDs to new data
    List<LandingPage> updatedPages = [];
    for (int x = 0; x < newLandingPages.length; x++) {
      updatedPages.add(
        newLandingPages[x].copyWith(
          landingPageId: old.landingPages[x].landingPageId,
          pseudoId: old.landingPages[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(
        old.copyWith(landingPages: updatedPages));
    await enterLandingPageData(tester);
  }

  static Future<void> deleteLandingPages(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.landingPages.length;
    expect(
      find.byKey(const Key('landingPageItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(
      tester,
      'delete0',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(
      tester,
      'deleteConfirm0',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('landingPageItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(landingPages: test.landingPages.sublist(1, count)),
    );
  }

  static Future<void> enterLandingPageData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<LandingPage> newPages = [];

    for (LandingPage page in test.landingPages) {
      if (page.pseudoId == null) {
        // Add new landing page
        await CommonTest.tapByKey(tester, 'addNewLandingPage');
      } else {
        // Update existing landing page
        await CommonTest.doNewSearch(tester, searchString: page.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').contains(page.pseudoId!),
          true,
        );
      }

      // Check for the detail screen (key varies based on pseudoId)
      final expectedKey = page.pseudoId == null
          ? 'LandingPageDetailnull'
          : 'LandingPageDetail${page.pseudoId}';
      expect(find.byKey(Key(expectedKey)), findsOneWidget);

      // Enter basic info
      await CommonTest.enterText(tester, 'title', page.title);
      await CommonTest.enterDropDown(tester, 'status', page.status);

      if (page.hookType != null) {
        await CommonTest.enterDropDown(tester, 'hookType', page.hookType!);
      }

      if (page.privacyPolicyUrl != null) {
        await CommonTest.enterText(
            tester, 'privacyPolicyUrl', page.privacyPolicyUrl!);
      }

      if (page.headline != null) {
        await CommonTest.enterText(tester, 'headline', page.headline!);
      }

      if (page.subheading != null) {
        await CommonTest.enterText(tester, 'subheading', page.subheading!);
      }

      if (page.ctaActionType != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'ctaActionType',
          listViewName: 'landingPageDialogListView',
        );
        await CommonTest.enterDropDown(
            tester, 'ctaActionType', page.ctaActionType!);
      }

      // Save the landing page
      await CommonTest.dragUntil(
        tester,
        key: 'landingPageDetailSave',
        listViewName: 'landingPageDialogListView',
      );
      await CommonTest.tapByKey(
        tester,
        'landingPageDetailSave',
        seconds: CommonTest.waitTime,
      );

      // Get allocated ID for new pages
      if (page.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'item0',
            seconds: CommonTest.waitTime);
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        page = page.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newPages.add(page);
    }

    await PersistFunctions.persistTest(test.copyWith(landingPages: newPages));
  }

  static Future<void> checkLandingPages(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (LandingPage page in test.landingPages) {
      await CommonTest.doNewSearch(tester, searchString: page.pseudoId!);

      // Check detail - the dialog key is LandingPageDetail${pseudoId}
      expect(
          find.byKey(Key('LandingPageDetail${page.pseudoId}')), findsOneWidget);
      expect(CommonTest.getTextFormField('title'), equals(page.title));

      if (page.headline != null) {
        expect(
          CommonTest.getTextFormField('headline'),
          equals(page.headline!),
        );
      }

      if (page.subheading != null) {
        expect(
          CommonTest.getTextFormField('subheading'),
          equals(page.subheading!),
        );
      }

      if (page.hookType != null) {
        expect(
          CommonTest.getDropdown('hookType'),
          equals(page.hookType!),
        );
      }

      if (page.ctaActionType != null) {
        expect(
          CommonTest.getDropdown('ctaActionType'),
          equals(page.ctaActionType!),
        );
      }

      expect(
        CommonTest.getDropdown('status'),
        equals(page.status),
      );

      if (page.privacyPolicyUrl != null) {
        expect(
          CommonTest.getTextFormField('privacyPolicyUrl'),
          equals(page.privacyPolicyUrl!),
        );
      }

      await CommonTest.tapByKey(tester, 'cancel');
    }
  }

  static Future<void> addPageSections(
    WidgetTester tester,
    List<LandingPageSection> sections,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    // Get the first landing page to add sections to
    if (test.landingPages.isEmpty) {
      throw Exception('No landing pages available to add sections to');
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to sections tab if exists, or sections button
    final sectionsKey = find.byKey(const Key('mobileSections'));
    if (sectionsKey.evaluate().isNotEmpty) {
      await tester.tap(sectionsKey);
      await tester.pumpAndSettle();
    }

    List<LandingPageSection> newSections = [];
    for (LandingPageSection section in sections) {
      // Add new section
      await CommonTest.tapByKey(tester, 'addSection',
          seconds: CommonTest.waitTime);

      // Fill in section details
      await CommonTest.enterText(tester, 'sectionTitle', section.sectionTitle!);

      if (section.sectionDescription != null) {
        await CommonTest.enterText(
            tester, 'sectionDescription', section.sectionDescription!);
      }

      if (section.sectionImageUrl != null) {
        await CommonTest.enterText(
            tester, 'sectionImageUrl', section.sectionImageUrl!);
      }

      if (section.sectionSequence != null) {
        await CommonTest.enterText(
            tester, 'sectionSequence', section.sectionSequence.toString());
      }

      // Save section
      await CommonTest.tapByKey(tester, 'saveSection',
          seconds: CommonTest.waitTime);

      newSections.add(section);
    }

    // Close the section page
    await CommonTest.tapByKey(tester, 'cancel');
    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Update landing page with sections
    List<LandingPage> updatedPages = List.from(test.landingPages);
    updatedPages[0] = updatedPages[0].copyWith(sections: newSections);
    await PersistFunctions.persistTest(
        test.copyWith(landingPages: updatedPages));
  }

  static Future<void> updatePageSections(
    WidgetTester tester,
    List<LandingPageSection> newSections,
  ) async {
    SaveTest test = await PersistFunctions.getTest();

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to sections tab if exists
    final sectionsKey = find.byKey(const Key('mobileSections'));
    if (sectionsKey.evaluate().isNotEmpty) {
      await tester.tap(sectionsKey);
      await tester.pumpAndSettle();
    }

    List<LandingPageSection> updatedSections = [];
    for (int x = 0; x < newSections.length; x++) {
      // Tap on section to edit
      await CommonTest.tapByKey(
          tester, 'section${newSections[x].sectionSequence}',
          seconds: CommonTest.waitTime);

      // Update section details
      await CommonTest.enterText(
          tester, 'sectionTitle', newSections[x].sectionTitle!);

      if (newSections[x].sectionDescription != null) {
        await CommonTest.enterText(
            tester, 'sectionDescription', newSections[x].sectionDescription!);
      }

      if (newSections[x].sectionImageUrl != null) {
        await CommonTest.enterText(
            tester, 'sectionImageUrl', newSections[x].sectionImageUrl!);
      }

      if (newSections[x].sectionSequence != null) {
        await CommonTest.enterText(tester, 'sectionSequence',
            newSections[x].sectionSequence.toString());
      }

      // Save section
      await CommonTest.tapByKey(tester, 'saveSection',
          seconds: CommonTest.waitTime);

      updatedSections.add(newSections[x]);
    }

    // Close the section page
    await CommonTest.tapByKey(tester, 'cancel');
    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Update landing page with sections
    List<LandingPage> updatedPages = List.from(test.landingPages);
    updatedPages[0] = updatedPages[0].copyWith(sections: updatedSections);
    await PersistFunctions.persistTest(
        test.copyWith(landingPages: updatedPages));
  }

  static Future<void> checkPageSections(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    if (test.landingPages.isEmpty ||
        test.landingPages[0].sections == null ||
        test.landingPages[0].sections!.isEmpty) {
      return;
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to sections tab if exists
    final sectionsKey = find.byKey(const Key('mobileSections'));
    if (sectionsKey.evaluate().isNotEmpty) {
      await tester.tap(sectionsKey);
      await tester.pumpAndSettle();
    }

    // Check each section
    for (int x = 0; x < test.landingPages[0].sections!.length; x++) {
      final section = test.landingPages[0].sections![x];

      // Find section in list by title
      expect(find.text(section.sectionTitle!), findsOneWidget);

      // Tap to open detail
      await CommonTest.tapByKey(tester, 'section${section.sectionSequence}',
          seconds: CommonTest.waitTime);

      // Verify section details
      expect(CommonTest.getTextFormField('sectionTitle'),
          equals(section.sectionTitle!));

      if (section.sectionDescription != null) {
        expect(CommonTest.getTextFormField('sectionDescription'),
            equals(section.sectionDescription!));
      }

      if (section.sectionImageUrl != null) {
        expect(CommonTest.getTextFormField('sectionImageUrl'),
            equals(section.sectionImageUrl!));
      }

      // Close section detail
      await CommonTest.tapByKey(tester, 'cancel');
      await tester.pumpAndSettle();
    }

    // Close the section page
    await CommonTest.tapByKey(tester, 'cancel');
    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> deletePageSection(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();

    if (test.landingPages.isEmpty ||
        test.landingPages[0].sections == null ||
        test.landingPages[0].sections!.isEmpty) {
      return;
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to sections tab if exists
    final sectionsKey = find.byKey(const Key('mobileSections'));
    if (sectionsKey.evaluate().isNotEmpty) {
      await tester.tap(sectionsKey);
      await tester.pumpAndSettle();
    }

    int count = test.landingPages[0].sections!.length;
    final lastSection = test.landingPages[0].sections!.last;

    // Find and tap delete button on last section
    final deleteButton = find.byIcon(Icons.delete).last;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm deletion
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify section was deleted
    expect(
      find.text(lastSection.sectionTitle!),
      findsNothing,
    );

    // Close the section page
    await CommonTest.tapByKey(tester, 'cancel');
    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Update landing page with remaining sections
    List<LandingPage> updatedPages = List.from(test.landingPages);
    updatedPages[0] = updatedPages[0].copyWith(
      sections: test.landingPages[0].sections!.sublist(0, count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(landingPages: updatedPages),
    );
  }

  static Future<void> addCredibilityInfo(
    WidgetTester tester,
    CredibilityInfo credibilityInfo,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.landingPages.isEmpty) {
      throw Exception('No landing pages available to add credibility to');
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to credibility tab if exists
    final credibilityKey = find.byKey(const Key('mobileCredibility'));
    if (credibilityKey.evaluate().isNotEmpty) {
      await tester.tap(credibilityKey);
      await tester.pumpAndSettle();
    }

    // Add credibility info
    await CommonTest.tapByKey(tester, 'addCredibility',
        seconds: CommonTest.waitTime);

    // Fill in credibility details
    if (credibilityInfo.creatorBio != null) {
      await CommonTest.enterText(
          tester, 'creatorBio', credibilityInfo.creatorBio!);
    }

    if (credibilityInfo.backgroundText != null) {
      await CommonTest.enterText(
          tester, 'backgroundText', credibilityInfo.backgroundText!);
    }

    if (credibilityInfo.creatorImageUrl != null) {
      await CommonTest.enterText(
          tester, 'creatorImageUrl', credibilityInfo.creatorImageUrl!);
    }

    // Save credibility info
    await CommonTest.dragUntil(
      tester,
      key: 'saveCredibility',
      listViewName: 'credibilityInfoScrollView',
    );
    await CommonTest.tapByKey(tester, 'saveCredibility',
        seconds: CommonTest.waitTime);

    // Get allocated ID for new credibility info
    await CommonTest.tapByKey(tester, 'item0', seconds: CommonTest.waitTime);
    var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
    credibilityInfo = credibilityInfo.copyWith(pseudoId: id);
    // close the credibility detail page
    await CommonTest.tapByKey(tester, 'cancel');

    // Close the credibility list page
    await CommonTest.tapByKey(tester, 'cancel');

    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Update landing page with credibility
    List<LandingPage> updatedPages = List.from(test.landingPages);
    updatedPages[0] = updatedPages[0].copyWith(credibility: credibilityInfo);
    await PersistFunctions.persistTest(
        test.copyWith(landingPages: updatedPages));
  }

  static Future<void> updateCredibilityInfo(
    WidgetTester tester,
    CredibilityInfo newCredibilityInfo,
  ) async {
    SaveTest test = await PersistFunctions.getTest();

    // copy pseudoId from current object
    newCredibilityInfo = newCredibilityInfo.copyWith(
        pseudoId: test.landingPages[0].credibility!.pseudoId);

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to credibility tab if exists
    final credibilityKey = find.byKey(const Key('mobileCredibility'));
    if (credibilityKey.evaluate().isNotEmpty) {
      await tester.tap(credibilityKey);
      await tester.pumpAndSettle();
    }

    // Tap on credibility info to edit
    await CommonTest.tapByKey(
        tester, 'credibilityItem${newCredibilityInfo.pseudoId}',
        seconds: CommonTest.waitTime);

    // Update credibility details
    if (newCredibilityInfo.creatorBio != null) {
      await CommonTest.enterText(
          tester, 'creatorBio', newCredibilityInfo.creatorBio!);
    }

    if (newCredibilityInfo.backgroundText != null) {
      await CommonTest.enterText(
          tester, 'backgroundText', newCredibilityInfo.backgroundText!);
    }

    if (newCredibilityInfo.creatorImageUrl != null) {
      await CommonTest.enterText(
          tester, 'creatorImageUrl', newCredibilityInfo.creatorImageUrl!);
    }

    // Handle statistics: with consolidated architecture, all statistics are replaced atomically
    if (newCredibilityInfo.statistics != null) {
      // Get current statistic count
      int existingCount =
          test.landingPages[0].credibility?.statistics?.length ?? 0;
      int newCount = newCredibilityInfo.statistics!.length;

      // If updating with different number of statistics, adjust rows
      if (newCount > existingCount) {
        // Add new statistic rows
        for (int i = existingCount; i < newCount; i++) {
          await CommonTest.tapByKey(tester, 'addStatistic',
              seconds: CommonTest.waitTime);
        }
      } else if (newCount < existingCount) {
        // Remove excess statistic rows from the end
        for (int i = 0; i < (existingCount - newCount); i++) {
          final deleteButton = find.byIcon(Icons.delete).last;
          await tester.tap(deleteButton);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Update all statistic values
      for (int i = 0; i < newCredibilityInfo.statistics!.length; i++) {
        final stat = newCredibilityInfo.statistics![i];
        if (stat.statistic != null) {
          await CommonTest.enterText(
            tester,
            'statistic$i',
            stat.statistic!,
          );
        }
      }
    }

    // Save credibility info
    await CommonTest.dragUntil(
      tester,
      key: 'saveCredibility',
      listViewName: 'credibilityInfoScrollView',
    );
    await CommonTest.tapByKey(tester, 'saveCredibility',
        seconds: CommonTest.waitTime);

    // Close the credibility list page
    await CommonTest.tapByKey(tester, 'cancel');
    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');

    // persist landing page with credibility
    List<LandingPage> updatedPages = List.from(test.landingPages);
    updatedPages[0] = updatedPages[0].copyWith(credibility: newCredibilityInfo);
    await PersistFunctions.persistTest(
        test.copyWith(landingPages: updatedPages));
  }

  static Future<void> checkCredibilityInfo(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    if (test.landingPages.isEmpty || test.landingPages[0].credibility == null) {
      return;
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to credibility tab if exists
    final credibilityKey = find.byKey(const Key('mobileCredibility'));
    if (credibilityKey.evaluate().isNotEmpty) {
      await tester.tap(credibilityKey);
      await tester.pumpAndSettle();
    }

    final credibility = test.landingPages[0].credibility!;

    // Tap to open detail
    await CommonTest.tapByKey(tester, 'credibilityItem${credibility.pseudoId}',
        seconds: CommonTest.waitTime);

    // Verify credibility details
    if (credibility.creatorBio != null) {
      expect(CommonTest.getTextFormField('creatorBio'),
          equals(credibility.creatorBio!));
    }

    if (credibility.backgroundText != null) {
      expect(CommonTest.getTextFormField('backgroundText'),
          equals(credibility.backgroundText!));
    }

    if (credibility.creatorImageUrl != null) {
      expect(CommonTest.getTextFormField('creatorImageUrl'),
          equals(credibility.creatorImageUrl!));
    }

    // Verify statistics are present in the form
    if (credibility.statistics != null && credibility.statistics!.isNotEmpty) {
      for (int i = 0; i < credibility.statistics!.length; i++) {
        final statistic = credibility.statistics![i];
        if (statistic.statistic != null) {
          // Verify each statistic text is in the form
          expect(
            CommonTest.getTextFormField('statistic$i'),
            equals(statistic.statistic!),
            reason: 'Statistic at index $i should match',
          );
        }
      }
    }

    // Close credibility detail
    await CommonTest.tapByKey(tester, 'cancel');
    await tester.pumpAndSettle();

    // Close the credibility section page
    await CommonTest.tapByKey(tester, 'cancel');
    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> addCredibilityStatistics(
    WidgetTester tester,
    List<CredibilityStatistic> statistics,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.landingPages.isEmpty || test.landingPages[0].credibility == null) {
      throw Exception('No credibility info available to add statistics to');
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to credibility tab if exists
    final credibilityKey = find.byKey(const Key('mobileCredibility'));
    if (credibilityKey.evaluate().isNotEmpty) {
      await tester.tap(credibilityKey);
      await tester.pumpAndSettle();
    }
    // Open the credibility info to edit
    await CommonTest.tapByKey(
        tester, 'credibilityItem${test.landingPages[0].credibility!.pseudoId}',
        seconds: CommonTest.waitTime);

    List<CredibilityStatistic> newStatistics = [];
    for (int i = 0; i < statistics.length; i++) {
      CredibilityStatistic statistic = statistics[i];
      // Add new statistic
      await CommonTest.tapByKey(tester, 'addStatistic',
          seconds: CommonTest.waitTime);

      // Fill in statistic details
      if (statistic.statistic != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'statistic$i',
          listViewName: 'credibilityInfoScrollView',
        );
        await CommonTest.enterText(tester, 'statistic$i', statistic.statistic!);
      }

      newStatistics.add(statistic);
    }

    // Save credibility info with statistics
    await CommonTest.dragUntil(
      tester,
      key: 'saveCredibility',
      listViewName: 'credibilityInfoScrollView',
    );
    await CommonTest.tapByKey(tester, 'saveCredibility',
        seconds: CommonTest.waitTime);

    // Close credibility detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Update landing page with statistics
    List<LandingPage> updatedPages = List.from(test.landingPages);
    final updatedCredibility = test.landingPages[0].credibility!.copyWith(
      statistics: newStatistics,
    );
    updatedPages[0] = updatedPages[0].copyWith(credibility: updatedCredibility);
    await PersistFunctions.persistTest(
        test.copyWith(landingPages: updatedPages));
  }

  static Future<void> checkCredibilityStatistics(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    if (test.landingPages.isEmpty ||
        test.landingPages[0].credibility == null ||
        test.landingPages[0].credibility!.statistics == null ||
        test.landingPages[0].credibility!.statistics!.isEmpty) {
      return;
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to credibility tab if exists
    final credibilityKey = find.byKey(const Key('mobileCredibility'));
    if (credibilityKey.evaluate().isNotEmpty) {
      await tester.tap(credibilityKey);
      await tester.pumpAndSettle();
    }

    // Open credibility info to verify statistics are persisted
    await CommonTest.tapByKey(tester, 'credibilityItem100000',
        seconds: CommonTest.waitTime);
    await tester.pumpAndSettle();

    // Verify each statistic is present and has correct value
    for (int i = 0;
        i < test.landingPages[0].credibility!.statistics!.length;
        i++) {
      final statistic = test.landingPages[0].credibility!.statistics![i];

      if (statistic.statistic != null) {
        // Verify statistic text is in the form with exact value
        expect(
          CommonTest.getTextFormField('statistic$i'),
          equals(statistic.statistic!),
          reason: 'Statistic $i should be "${statistic.statistic!}"',
        );
      }
    }

    // Close credibility detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Close credibility list
    await CommonTest.tapByKey(tester, 'cancel');

    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> deleteCredibilityStatistic(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();

    if (test.landingPages.isEmpty ||
        test.landingPages[0].credibility == null ||
        test.landingPages[0].credibility!.statistics == null ||
        test.landingPages[0].credibility!.statistics!.isEmpty) {
      return;
    }

    // Open the first landing page
    await CommonTest.doNewSearch(tester,
        searchString: test.landingPages[0].pseudoId!);
    await tester.pumpAndSettle();

    // Navigate to credibility tab if exists
    final credibilityKey = find.byKey(const Key('mobileCredibility'));
    if (credibilityKey.evaluate().isNotEmpty) {
      await tester.tap(credibilityKey);
      await tester.pumpAndSettle();
    }

    // Open the credibility info to edit
    await CommonTest.tapByKey(
        tester, 'credibilityItem${test.landingPages[0].credibility!.pseudoId}',
        seconds: CommonTest.waitTime);

    int count = test.landingPages[0].credibility!.statistics!.length;

    // Find and tap delete button on last statistic
    final deleteButton = find.byIcon(Icons.delete).last;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Save credibility info
    await CommonTest.tapByKey(tester, 'saveCredibility',
        seconds: CommonTest.waitTime);

    // Close credibility list
    await CommonTest.tapByKey(tester, 'cancel');

    // Close the landing page detail
    await CommonTest.tapByKey(tester, 'cancel');

    // Update landing page with remaining statistics
    List<LandingPage> updatedPages = List.from(test.landingPages);
    final updatedCredibility = test.landingPages[0].credibility!.copyWith(
      statistics:
          test.landingPages[0].credibility!.statistics!.sublist(0, count - 1),
    );
    updatedPages[0] = updatedPages[0].copyWith(credibility: updatedCredibility);
    await PersistFunctions.persistTest(
      test.copyWith(landingPages: updatedPages),
    );
  }
}
