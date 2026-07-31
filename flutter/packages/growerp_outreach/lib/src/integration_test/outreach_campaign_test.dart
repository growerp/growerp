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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Formats backend status for display (mirrors the UI formatting)
/// 'MKTG_CAMP_PLANNED' -> 'Planned'
String _formatStatus(String status) {
  final cleaned = status.replaceFirst('MKTG_CAMP_', '');
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

/// Integration test class for OutreachCampaign following the LandingPageTest pattern.
/// Uses external test data and PersistFunctions to manage test state.
class OutreachCampaignTest {
  /// The send-window dropdowns show local hours while the backend stores UTC,
  /// mirror the screen's conversion. Empty means 'no restriction'.
  static String _hourValue(int? utcHour) => utcHour == null
      ? ''
      : ((utcHour + DateTime.now().timeZoneOffset.inHours + 24) % 24)
          .toString();

  static String _hourLabel(int? utcHour) {
    final value = _hourValue(utcHour);
    return value.isEmpty ? 'Any time' : '${value.padLeft(2, '0')}:00';
  }

  /// Only touch the dropdown when the wanted hour is not already selected:
  /// re-picking the shown value makes the option text ambiguous, the closed
  /// field and the open menu then both carry it.
  static Future<void> _selectHour(
    WidgetTester tester,
    String key,
    int? utcHour,
  ) async {
    if (CommonTest.getDropdown(key) == _hourValue(utcHour)) return;
    await CommonTest.selectDropDown(tester, key, _hourLabel(utcHour));
  }

  /// Campaign platform chips can only be selected when the platform has an
  /// enabled configuration, so create the ones used by the test data.
  static Future<void> enablePlatforms(
    RestClient restClient, [
    List<String> platforms = const ['EMAIL', 'LINKEDIN'],
  ]) async {
    final existing = (await restClient.listPlatformConfigurations())
        .configs
        .map((config) => config.platform.toUpperCase())
        .toSet();
    for (final platform in platforms) {
      if (existing.contains(platform)) continue;
      await restClient.createPlatformConfiguration(
        platform: platform,
        isEnabled: 'Y',
      );
    }
  }

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
    await CommonTest.tapByKey(tester, 'delete0', seconds: CommonTest.waitTime);
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

  /// Searches for a campaign using the inline ListFilterBar search
  /// and taps the first result to open the detail dialog.
  static Future<void> searchAndOpenCampaign(
    WidgetTester tester,
    String searchString,
  ) async {
    await CommonTest.doNewSearch(tester, searchString: searchString);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// Clears the search field to reset the list to show all campaigns.
  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pump(const Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// Internal method to enter campaign data.
  /// Handles both creation and update of campaigns.
  static Future<void> enterCampaignData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<OutreachCampaign> newCampaigns = [];

    for (OutreachCampaign campaign in test.outreachCampaigns) {
      // Determine if this is a new campaign or existing one
      // Backend pseudoIds are 6-digit numbers (e.g., '100000')
      // Test data uses simple numbers like '1', '2', '3'
      final isExisting =
          campaign.pseudoId != null && campaign.pseudoId!.length >= 5;

      if (isExisting) {
        // Update existing campaign - use search by pseudoId
        // (name may have changed in updatedCampaigns)
        await searchAndOpenCampaign(tester, campaign.pseudoId!);
      } else {
        // Add new campaign
        await CommonTest.tapByKey(tester, 'addNew');
        await tester.pumpAndSettle();
      }

      // Enter campaign name
      await CommonTest.enterText(tester, 'name', campaign.name);

      // Enter description
      if (campaign.description != null) {
        await CommonTest.enterText(tester, 'description', campaign.description!);
      }

      // Select status (tap on formatted display text)
      await CommonTest.tapByKey(tester, 'status');
      await CommonTest.tapByText(tester, _formatStatus(campaign.status));

      // Enter target audience
      if (campaign.targetAudience != null) {
        await tester.ensureVisible(find.byKey(const Key('targetAudience')));
        await CommonTest.enterText(
          tester,
          'targetAudience',
          campaign.targetAudience!,
        );
      }

      // Enter message template
      if (campaign.messageTemplate != null) {
        await tester.ensureVisible(find.byKey(const Key('messageTemplate')));
        await CommonTest.enterText(
          tester,
          'messageTemplate',
          campaign.messageTemplate!,
        );
      }

      // Enter email subject
      if (campaign.emailSubject != null) {
        await tester.ensureVisible(find.byKey(const Key('emailSubject')));
        await CommonTest.enterText(
          tester,
          'emailSubject',
          campaign.emailSubject!,
        );
      }

      // Enter daily limit
      await tester.ensureVisible(find.byKey(const Key('dailyLimit')));
      await CommonTest.enterText(
        tester,
        'dailyLimit',
        campaign.dailyLimitPerPlatform.toString(),
      );

      // Send window, entered in local hours and stored as UTC
      await tester.ensureVisible(find.byKey(const Key('sendFromHour')));
      await _selectHour(tester, 'sendFromHour', campaign.sendFromHour);
      await _selectHour(tester, 'sendToHour', campaign.sendToHour);

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
          // Target the selection FilterChip specifically: the bare platform
          // text also appears in the campaign list row behind the (desktop)
          // dialog, so a plain find.text matches several widgets and the
          // ensureVisible below throws "Too many elements".
          final chipFinder = find.widgetWithText(FilterChip, platform);
          if (tester.any(chipFinder)) {
            await tester.ensureVisible(chipFinder.first);
            await tester.tap(chipFinder.first);
            await tester.pumpAndSettle();
          }
        }
      }

      // Save the campaign using key (more reliable than text)
      await tester.ensureVisible(find.byKey(const Key('update')));
      await CommonTest.tapByKey(tester, 'update');
      // Wait for dialog to close and list to refresh
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

      // Clear search to show full list
      if (isExisting) {
        await clearSearch(tester);
      }

      // Get allocated pseudoId from the list for new campaigns
      if (!isExisting) {
        // The new campaign should be at index 0 in the list (newest first by -fromDate)
        // Read the id from the first table row (id0)
        final idFinder = find.byKey(const Key('id0'));
        if (tester.any(idFinder)) {
          final Text idText = tester.widget<Text>(idFinder);
          campaign = campaign.copyWith(pseudoId: idText.data);
        }
      }

      newCampaigns.add(campaign);
    }

    await PersistFunctions.persistTest(
      test.copyWith(outreachCampaigns: newCampaigns),
    );
  }

  /// Approves the campaign at [index] and verifies nothing else changed:
  /// approving sends a partial update, which used to null out every field
  /// the update did not carry (and regenerate the pseudoId).
  static Future<void> approveCampaign(WidgetTester tester, int index) async {
    SaveTest test = await PersistFunctions.getTest();
    OutreachCampaign campaign = test.outreachCampaigns[index];

    await searchAndOpenCampaign(tester, campaign.pseudoId!);
    await CommonTest.tapByKey(tester, 'status');
    await CommonTest.tapByText(tester, _formatStatus('MKTG_CAMP_APPROVED'));
    await tester.ensureVisible(find.byKey(const Key('update')));
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await clearSearch(tester);

    // Re-open by the same pseudoId: a regenerated id would not be found
    await searchAndOpenCampaign(tester, campaign.pseudoId!);
    expect(
      find.byKey(Key('CampaignDetail${campaign.pseudoId}')),
      findsOneWidget,
      reason: 'campaign ${campaign.pseudoId} lost its id when approved',
    );

    expect(CommonTest.getTextFormField('name'), equals(campaign.name),
        reason: 'name lost when approved');
    expect(CommonTest.getTextFormField('description'),
        equals(campaign.description),
        reason: 'description lost when approved');
    expect(CommonTest.getTextFormField('targetAudience'),
        equals(campaign.targetAudience),
        reason: 'targetAudience lost when approved');
    expect(CommonTest.getTextFormField('messageTemplate'),
        equals(campaign.messageTemplate),
        reason: 'messageTemplate lost when approved');
    expect(
        CommonTest.getTextFormField('emailSubject'), equals(campaign.emailSubject),
        reason: 'emailSubject lost when approved');
    expect(CommonTest.getTextFormField('dailyLimit'),
        equals(campaign.dailyLimitPerPlatform.toString()),
        reason: 'dailyLimit lost when approved');

    // Platform chips must still be selected
    final platforms = campaign.platforms
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final platform in platforms) {
      final chipFinder = find.widgetWithText(FilterChip, platform);
      expect(tester.any(chipFinder), isTrue,
          reason: 'platform $platform not shown after approval');
      expect(tester.widget<FilterChip>(chipFinder.first).selected, isTrue,
          reason: 'platform $platform lost when approved');
    }

    // The automation moves the status on asynchronously (in progress/completed
    // /failed), so only check it is no longer the original one.
    expect(_formatStatus(CommonTest.getDropdown('status')),
        isNot(equals(_formatStatus(campaign.status))),
        reason: 'status not changed by approval');

    await CommonTest.tapByKey(tester, 'cancel');
    await tester.pumpAndSettle();
    await clearSearch(tester);
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
      expect(CommonTest.getTextFormField('name'), equals(campaign.name));

      // Verify description
      if (campaign.description != null) {
        expect(
          CommonTest.getTextFormField('description'),
          equals(campaign.description),
        );
      }

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

      // Verify send window (shown in local hours, stored as UTC)
      expect(
        CommonTest.getDropdown('sendFromHour'),
        equals(_hourValue(campaign.sendFromHour)),
        reason: 'sendFromHour lost or not converted back to local time',
      );
      expect(
        CommonTest.getDropdown('sendToHour'),
        equals(_hourValue(campaign.sendToHour)),
        reason: 'sendToHour lost or not converted back to local time',
      );

      // Verify status (compare formatted values for consistency with UI)
      expect(
        _formatStatus(CommonTest.getDropdown('status')),
        equals(_formatStatus(campaign.status)),
      );

      // Close dialog by tapping cancel button
      await CommonTest.tapByKey(tester, 'cancel');
      await tester.pumpAndSettle();

      // Clear search to reset list for next campaign
      await clearSearch(tester);
    }
  }
}
