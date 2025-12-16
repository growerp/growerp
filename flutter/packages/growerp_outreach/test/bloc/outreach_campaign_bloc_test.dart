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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_outreach/src/bloc/outreach_campaign_bloc.dart';

void main() {
  group('OutreachCampaignState', () {
    test('should have correct initial state', () {
      const state = OutreachCampaignState();

      expect(state.status, equals(OutreachCampaignStatus.initial));
      expect(state.campaigns, isEmpty);
      expect(state.message, isNull);
      expect(state.hasReachedMax, isFalse);
    });

    test('copyWith should preserve unchanged values', () {
      const original = OutreachCampaignState(
        status: OutreachCampaignStatus.success,
        campaigns: [],
        hasReachedMax: true,
      );

      final copied = original.copyWith(
        message: 'New message',
      );

      expect(copied.status, equals(OutreachCampaignStatus.success));
      expect(copied.hasReachedMax, isTrue);
      expect(copied.message, equals('New message'));
    });

    test('copyWith should update specified values', () {
      const original = OutreachCampaignState();

      final copied = original.copyWith(
        status: OutreachCampaignStatus.loading,
        hasReachedMax: true,
      );

      expect(copied.status, equals(OutreachCampaignStatus.loading));
      expect(copied.hasReachedMax, isTrue);
    });

    test('props should include all properties', () {
      const state1 = OutreachCampaignState(
        status: OutreachCampaignStatus.success,
        message: 'test',
      );

      const state2 = OutreachCampaignState(
        status: OutreachCampaignStatus.success,
        message: 'test',
      );

      const state3 = OutreachCampaignState(
        status: OutreachCampaignStatus.failure,
        message: 'test',
      );

      expect(state1.props, equals(state2.props));
      expect(state1.props, isNot(equals(state3.props)));
    });
  });

  group('OutreachCampaignEvent', () {
    test('OutreachCampaignFetch should include filters in props', () {
      const event =
          OutreachCampaignFetch(status: 'ACTIVE', start: 0, limit: 20);
      expect(event.props, contains('ACTIVE'));
      expect(event.props, contains(0));
      expect(event.props, contains(20));
    });

    test('OutreachCampaignCreate should include all fields in props', () {
      const event = OutreachCampaignCreate(
        name: 'Test Campaign',
        platforms: 'EMAIL,LINKEDIN',
        targetAudience: 'developers',
        dailyLimitPerPlatform: 50,
      );

      expect(event.name, equals('Test Campaign'));
      expect(event.platforms, equals('EMAIL,LINKEDIN'));
      expect(event.props, contains('Test Campaign'));
      expect(event.props, contains('EMAIL,LINKEDIN'));
    });

    test('OutreachCampaignUpdate should include campaignId in props', () {
      const event = OutreachCampaignUpdate(
        campaignId: 'test-456',
        name: 'Updated Campaign',
        status: 'PAUSED',
      );

      expect(event.campaignId, equals('test-456'));
      expect(event.name, equals('Updated Campaign'));
      expect(event.props, contains('test-456'));
    });

    test('OutreachCampaignDelete should include campaignId in props', () {
      const event = OutreachCampaignDelete('test-789');

      expect(event.campaignId, equals('test-789'));
      expect(event.props, contains('test-789'));
    });

    test('OutreachCampaignStart should include campaignId in props', () {
      const event = OutreachCampaignStart('test-start');

      expect(event.campaignId, equals('test-start'));
      expect(event.props, contains('test-start'));
    });

    test('OutreachCampaignPause should include campaignId in props', () {
      const event = OutreachCampaignPause('test-pause');

      expect(event.campaignId, equals('test-pause'));
      expect(event.props, contains('test-pause'));
    });

    test('OutreachCampaignDetailFetch should support both id types', () {
      const event1 = OutreachCampaignDetailFetch(campaignId: 'abc-123');
      const event2 = OutreachCampaignDetailFetch(pseudoId: 'CAMP001');

      expect(event1.campaignId, equals('abc-123'));
      expect(event2.pseudoId, equals('CAMP001'));
    });

    test('OutreachCampaignSearchRequested should include query', () {
      const event = OutreachCampaignSearchRequested(query: 'marketing');

      expect(event.query, equals('marketing'));
      expect(event.limit, equals(20));
      expect(event.props, contains('marketing'));
    });
  });

  group('OutreachCampaignStatus', () {
    test('should have all expected values', () {
      expect(OutreachCampaignStatus.values,
          contains(OutreachCampaignStatus.initial));
      expect(OutreachCampaignStatus.values,
          contains(OutreachCampaignStatus.loading));
      expect(OutreachCampaignStatus.values,
          contains(OutreachCampaignStatus.success));
      expect(OutreachCampaignStatus.values,
          contains(OutreachCampaignStatus.failure));
    });
  });
}
