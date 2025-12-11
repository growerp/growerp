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

/// Integration test class for OutreachCampaign following the LandingPageTest pattern.
/// Uses external test data and PersistFunctions to manage test state.
class OutreachCampaignTest {
  /// Navigates to the campaigns list screen.
  static Future<void> selectCampaigns(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/campaigns',
      'CampaignListScreen',
      null,
    );
  }

  /// Adds campaigns using the provided test data.
  /// Persists campaigns to SaveTest for later retrieval.
  static Future<void> addCampaigns(
    WidgetTester tester,
    List<OutreachCampaign> campaigns,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
      test.copyWith(outreachCampaigns: campaigns),
    );
    await enterCampaignData(tester);
  }

  /// Updates campaigns with new data.
  /// Copies IDs from persisted campaigns to new data.
  static Future<void> updateCampaigns(
    WidgetTester tester,
    List<OutreachCampaign> newCampaigns,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // Copy IDs to new data
    List<OutreachCampaign> updatedCampaigns = [];
    for (int x = 0; x < newCampaigns.length; x++) {
      updatedCampaigns.add(
        newCampaigns[x].copyWith(
          campaignId: old.outreachCampaigns[x].campaignId,
          pseudoId: old.outreachCampaigns[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(
      old.copyWith(outreachCampaigns: updatedCampaigns),
    );
    await enterCampaignData(tester);
  }

  /// Deletes the first campaign in the list.
  static Future<void> deleteCampaigns(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.outreachCampaigns.length;
    expect(
      find.byKey(const Key('campaignItem'), skipOffstage: false),
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
      find.byKey(const Key('campaignItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(
        outreachCampaigns: test.outreachCampaigns.sublist(1, count),
      ),
    );
  }

  /// Opens the search dialog and searches for a campaign by name.
  /// Then clicks on the first search result to open the detail dialog.
  static Future<void> searchAndOpenCampaign(
    WidgetTester tester,
    String searchString,
  ) async {
    // Tap on search FAB
    await CommonTest.tapByKey(tester, 'search');
    await tester.pumpAndSettle();

    // Enter search text in search field
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pumpAndSettle();

    // Submit the search (press Enter)
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Tap on the first search result
    await CommonTest.tapByKey(tester, 'campaignSearchItem0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// Internal method to enter campaign data.
  /// Handles both creation and update of campaigns.
  static Future<void> enterCampaignData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<OutreachCampaign> newCampaigns = [];
    int index = 0;

    for (OutreachCampaign campaign in test.outreachCampaigns) {
      if (campaign.campaignId == null) {
        // Add new campaign
        await CommonTest.tapByKey(tester, 'addNew');
        await tester.pumpAndSettle();
      } else {
        // Update existing campaign - use search to find it
        await searchAndOpenCampaign(tester, campaign.name);
      }

      // Enter campaign name
      await CommonTest.enterText(tester, 'name', campaign.name);

      // Select status
      await CommonTest.tapByKey(tester, 'status');
      await CommonTest.tapByText(tester, campaign.status);

      // Enter target audience
      if (campaign.targetAudience != null) {
        await CommonTest.enterText(
          tester,
          'targetAudience',
          campaign.targetAudience!,
        );
      }

      // Enter message template
      if (campaign.messageTemplate != null) {
        await CommonTest.enterText(
          tester,
          'messageTemplate',
          campaign.messageTemplate!,
        );
      }

      // Enter email subject
      if (campaign.emailSubject != null) {
        await CommonTest.enterText(
          tester,
          'emailSubject',
          campaign.emailSubject!,
        );
      }

      // Enter daily limit
      await CommonTest.enterText(
        tester,
        'dailyLimit',
        campaign.dailyLimitPerPlatform.toString(),
      );

      // Handle platforms (FilterChips)
      if (campaign.platforms.isNotEmpty && campaign.platforms != '[]') {
        final platforms = campaign.platforms
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        for (var platform in platforms) {
          // Use ensureVisible since chips might be wrapped
          final chipFinder = find.text(platform);
          if (tester.any(chipFinder)) {
            await tester.ensureVisible(chipFinder);
            await tester.tap(chipFinder);
            await tester.pumpAndSettle();
          }
        }
      }

      // Save the campaign
      if (campaign.campaignId == null) {
        await CommonTest.tapByText(tester, 'Create');
      } else {
        await CommonTest.tapByText(tester, 'Update');
      }
      // Wait for dialog to close and list to refresh
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

      // Get allocated pseudoId from the list for new campaigns
      if (campaign.campaignId == null) {
        // The new campaign should be first in the list (index 0)
        // Read the id from the table row key
        final idFinder = find.byKey(Key('id$index'));
        if (tester.any(idFinder)) {
          final Text idText = tester.widget<Text>(idFinder);
          campaign = campaign.copyWith(pseudoId: idText.data);
        }
      }

      newCampaigns.add(campaign);
      index++;
    }

    await PersistFunctions.persistTest(
      test.copyWith(outreachCampaigns: newCampaigns),
    );
  }

  /// Verifies all campaigns in the persisted list.
  static Future<void> checkCampaigns(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (int i = 0; i < test.outreachCampaigns.length; i++) {
      OutreachCampaign campaign = test.outreachCampaigns[i];

      // Open campaign detail using the search dialog
      await searchAndOpenCampaign(tester, campaign.name);

      // Check detail dialog is open
      expect(
        find.byKey(Key('CampaignDetail${campaign.pseudoId}')),
        findsOneWidget,
        reason: 'Campaign detail dialog not open for ${campaign.pseudoId}',
      );

      // Verify campaign name
      expect(
        CommonTest.getTextFormField('name'),
        equals(campaign.name),
      );

      // Verify target audience
      if (campaign.targetAudience != null) {
        expect(
          CommonTest.getTextFormField('targetAudience'),
          equals(campaign.targetAudience),
        );
      }

      // Verify message template
      if (campaign.messageTemplate != null) {
        expect(
          CommonTest.getTextFormField('messageTemplate'),
          equals(campaign.messageTemplate),
        );
      }

      // Verify email subject
      if (campaign.emailSubject != null) {
        expect(
          CommonTest.getTextFormField('emailSubject'),
          equals(campaign.emailSubject),
        );
      }

      // Verify daily limit
      expect(
        CommonTest.getTextFormField('dailyLimit'),
        equals(campaign.dailyLimitPerPlatform.toString()),
      );

      // Verify status
      expect(
        CommonTest.getDropdown('status'),
        equals(campaign.status),
      );

      // Close dialog by tapping cancel button
      await CommonTest.tapByKey(tester, 'cancel');
      await tester.pumpAndSettle();
    }
  }
}
