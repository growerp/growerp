import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_outreach/src/bloc/outreach_message_event.dart';
import 'package:growerp_outreach/src/bloc/outreach_message_state.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(
      const OutreachCampaign(name: '', platforms: '', status: ''),
    );
    registerFallbackValue(User());
  });
  setUp(() => restClient = MockRestClient());

  group('OutreachCampaignBloc', () {
    late MockCampaignAutomationService automation;

    const spring = OutreachCampaign(
      campaignId: 'C1',
      name: 'Spring',
      platforms: '["EMAIL"]',
      status: 'MKTG_CAMP_PLANNED',
    );
    const summer = OutreachCampaign(
      campaignId: 'C2',
      name: 'Summer',
      platforms: '["LINKEDIN"]',
      status: 'MKTG_CAMP_PLANNED',
    );

    TypeMatcher<OutreachCampaignState> campaignState(
      OutreachCampaignStatus status, {
      List<OutreachCampaign>? campaigns,
      String? message,
    }) {
      var m = isA<OutreachCampaignState>().having(
        (s) => s.status,
        'status',
        status,
      );
      if (campaigns != null) {
        m = m.having((s) => s.campaigns, 'campaigns', campaigns);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    setUp(() {
      automation = MockCampaignAutomationService();
      when(() => automation.startCampaign(any())).thenAnswer((_) async {});
      when(() => automation.pauseCampaign(any())).thenAnswer((_) async {});
    });

    OutreachCampaignBloc build() =>
        OutreachCampaignBloc(restClient, automationService: automation);

    void stubRefresh(List<OutreachCampaign> list) => when(
      () => restClient.listOutreachCampaigns(),
    ).thenAnswer((_) async => OutreachCampaigns(campaigns: list));

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignFetch_firstPage_clearsThenLoads',
      setUp: () =>
          when(
            () => restClient.listOutreachCampaigns(start: 0, limit: 20),
          ).thenAnswer(
            (_) async => const OutreachCampaigns(campaigns: [spring, summer]),
          ),
      build: build,
      act: (bloc) => bloc.add(const OutreachCampaignFetch()),
      expect: () => [
        campaignState(OutreachCampaignStatus.loading, campaigns: []),
        campaignState(
          OutreachCampaignStatus.success,
          campaigns: [spring, summer],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignFetch_nextPage_appends',
      setUp: () => when(
        () => restClient.listOutreachCampaigns(start: 1, limit: 20),
      ).thenAnswer((_) async => const OutreachCampaigns(campaigns: [summer])),
      build: build,
      seed: () => const OutreachCampaignState(campaigns: [spring]),
      act: (bloc) => bloc.add(const OutreachCampaignFetch(start: 1)),
      expect: () => [
        campaignState(
          OutreachCampaignStatus.success,
          campaigns: [spring, summer],
        ),
      ],
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.listOutreachCampaigns(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const OutreachCampaignFetch()),
      expect: () => [
        campaignState(OutreachCampaignStatus.loading),
        campaignState(OutreachCampaignStatus.failure, message: 'No access'),
      ],
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignCreate_fields_sendsCampaignMapAndRefreshes',
      setUp: () {
        when(
          () => restClient.createOutreachCampaign(
            campaign: any(named: 'campaign'),
          ),
        ).thenAnswer((_) async => spring);
        stubRefresh([spring]);
      },
      build: build,
      act: (bloc) => bloc.add(
        const OutreachCampaignCreate(
          name: 'Spring',
          platforms: '["EMAIL"]',
          emailSubject: 'Hello',
          sendFromHour: 9,
        ),
      ),
      expect: () => [
        campaignState(OutreachCampaignStatus.loading),
        campaignState(
          OutreachCampaignStatus.success,
          campaigns: [spring],
          message: 'Campaign created successfully',
        ),
      ],
      verify: (_) {
        final sent =
            verify(
                  () => restClient.createOutreachCampaign(
                    campaign: captureAny(named: 'campaign'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(sent['campaignName'], 'Spring');
        expect(sent['emailSubject'], 'Hello');
        expect(sent['dailyLimitPerPlatform'], 50);
        expect(sent['sendFromHour'], 9);
      },
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignUpdate_approved_startsAutomation',
      setUp: () {
        when(
          () => restClient.updateOutreachCampaign(
            campaign: any(named: 'campaign'),
          ),
        ).thenAnswer((_) async => spring);
        when(
          () => restClient.getOutreachCampaignDetail(marketingCampaignId: 'C1'),
        ).thenAnswer((_) async => const CampaignDetail(campaign: spring));
        stubRefresh([spring]);
      },
      build: build,
      act: (bloc) => bloc.add(
        const OutreachCampaignUpdate(
          campaignId: 'C1',
          status: 'MKTG_CAMP_APPROVED',
        ),
      ),
      expect: () => [
        campaignState(OutreachCampaignStatus.loading),
        campaignState(
          OutreachCampaignStatus.success,
          message: 'Campaign approved and started',
        ),
      ],
      verify: (_) => verify(() => automation.startCampaign(spring)).called(1),
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignUpdate_approvedWithMeetingUrlButNoBookingPage_warns',
      setUp: () {
        const withLink = OutreachCampaign(
          campaignId: 'C1',
          name: 'Spring',
          platforms: '["EMAIL"]',
          status: 'MKTG_CAMP_APPROVED',
          messageTemplate: 'Book a call: {meetingUrl}',
        );
        when(
          () => restClient.updateOutreachCampaign(
            campaign: any(named: 'campaign'),
          ),
        ).thenAnswer((_) async => withLink);
        when(
          () => restClient.getOutreachCampaignDetail(marketingCampaignId: 'C1'),
        ).thenAnswer((_) async => const CampaignDetail(campaign: withLink));
        stubRefresh([withLink]);
      },
      build: build,
      act: (bloc) => bloc.add(
        const OutreachCampaignUpdate(
          campaignId: 'C1',
          status: 'MKTG_CAMP_APPROVED',
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.message, contains('no booking page is set')),
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignUpdate_otherStatus_doesNotStartAutomation',
      setUp: () {
        when(
          () => restClient.updateOutreachCampaign(
            campaign: any(named: 'campaign'),
          ),
        ).thenAnswer((_) async => spring);
        stubRefresh([spring]);
      },
      build: build,
      act: (bloc) =>
          bloc.add(const OutreachCampaignUpdate(campaignId: 'C1', name: 'X')),
      expect: () => [
        campaignState(OutreachCampaignStatus.loading),
        campaignState(
          OutreachCampaignStatus.success,
          message: 'Campaign updated successfully',
        ),
      ],
      verify: (_) => verifyNever(() => automation.startCampaign(any())),
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignDelete_campaign_deletesAndRefreshes',
      setUp: () {
        when(
          () => restClient.deleteOutreachCampaign(marketingCampaignId: 'C1'),
        ).thenAnswer((_) async {});
        stubRefresh([summer]);
      },
      build: build,
      seed: () => const OutreachCampaignState(campaigns: [spring, summer]),
      act: (bloc) => bloc.add(const OutreachCampaignDelete('C1')),
      expect: () => [
        campaignState(OutreachCampaignStatus.success, campaigns: [summer]),
      ],
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignDetailFetch_campaign_setsSelectedMessagesMetrics',
      setUp: () =>
          when(
            () =>
                restClient.getOutreachCampaignDetail(marketingCampaignId: 'C1'),
          ).thenAnswer(
            (_) async => const CampaignDetail(
              campaign: spring,
              metrics: CampaignMetrics(messagesSent: 5),
            ),
          ),
      build: build,
      act: (bloc) =>
          bloc.add(const OutreachCampaignDetailFetch(campaignId: 'C1')),
      expect: () => [
        campaignState(OutreachCampaignStatus.loading),
        campaignState(OutreachCampaignStatus.success)
            .having((s) => s.selectedCampaign, 'selected', spring)
            .having((s) => s.metrics?.messagesSent, 'sent', 5),
      ],
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignPause_campaign_stopsAutomationAndRefreshes',
      setUp: () => stubRefresh([spring]),
      build: build,
      act: (bloc) => bloc.add(const OutreachCampaignPause('C1')),
      expect: () => [
        campaignState(
          OutreachCampaignStatus.success,
          message: 'Campaign paused',
        ),
      ],
      verify: (_) => verify(() => automation.pauseCampaign('C1')).called(1),
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignStart_campaignInList_startsIt',
      setUp: () {
        when(
          () => restClient.getOutreachCampaignDetail(marketingCampaignId: 'C2'),
        ).thenAnswer((_) async => const CampaignDetail(campaign: summer));
        stubRefresh([summer]);
      },
      build: build,
      seed: () => const OutreachCampaignState(campaigns: [spring, summer]),
      act: (bloc) => bloc.add(const OutreachCampaignStart('C2')),
      expect: () => [
        campaignState(
          OutreachCampaignStatus.success,
          message: 'Campaign started',
        ),
      ],
      verify: (_) => verify(() => automation.startCampaign(summer)).called(1),
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignGenerateWithAI_goal_insertsGeneratedFirst',
      setUp: () => when(
        () => restClient.generateOutreachCampaignWithAI(
          campaignGoal: 'More demos',
          platforms: 'EMAIL',
        ),
      ).thenAnswer((_) async => summer),
      build: build,
      seed: () => const OutreachCampaignState(campaigns: [spring]),
      act: (bloc) => bloc.add(
        const OutreachCampaignGenerateWithAI(
          campaignGoal: 'More demos',
          platforms: 'EMAIL',
        ),
      ),
      expect: () => [
        campaignState(OutreachCampaignStatus.loading),
        campaignState(
          OutreachCampaignStatus.success,
          campaigns: [summer, spring],
        ),
      ],
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignSearchRequested_blank_clearsResultsWithoutBackend',
      build: build,
      act: (bloc) =>
          bloc.add(const OutreachCampaignSearchRequested(query: '  ')),
      expect: () => [
        isA<OutreachCampaignState>()
            .having(
              (s) => s.searchStatus,
              'searchStatus',
              OutreachCampaignStatus.success,
            )
            .having((s) => s.searchResults, 'results', isEmpty),
      ],
      verify: (_) => verifyZeroInteractions(restClient),
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachCampaignSearchRequested_query_setsSearchResultsOnly',
      setUp: () => when(
        () => restClient.listOutreachCampaigns(
          start: 0,
          limit: 20,
          searchString: 'Spr',
        ),
      ).thenAnswer((_) async => const OutreachCampaigns(campaigns: [spring])),
      build: build,
      act: (bloc) =>
          bloc.add(const OutreachCampaignSearchRequested(query: ' Spr ')),
      expect: () => [
        isA<OutreachCampaignState>().having(
          (s) => s.searchStatus,
          'searchStatus',
          OutreachCampaignStatus.loading,
        ),
        isA<OutreachCampaignState>()
            .having((s) => s.searchResults, 'results', [spring])
            .having((s) => s.campaigns, 'campaigns', isEmpty),
      ],
    );

    blocTest<OutreachCampaignBloc, OutreachCampaignState>(
      'OutreachPublishScheduledSocialPosts_fails_isSwallowed',
      setUp: () => when(
        () => restClient.publishScheduledSocialPosts(),
      ).thenThrow(dioError('X down')),
      build: build,
      act: (bloc) => bloc.add(const OutreachPublishScheduledSocialPosts()),
      expect: () => <OutreachCampaignState>[],
    );
  });

  group('OutreachMessageBloc', () {
    const pending = OutreachMessage(
      messageId: 'M1',
      platform: 'EMAIL',
      messageContent: 'Hi {name}',
      status: 'PENDING',
    );
    const failed = OutreachMessage(
      messageId: 'M2',
      platform: 'EMAIL',
      messageContent: 'Hi',
      status: 'FAILED',
    );

    TypeMatcher<OutreachMessageState> msgState(
      OutreachMessageStatus status, {
      List<OutreachMessage>? messages,
      String? message,
    }) {
      var m = isA<OutreachMessageState>().having(
        (s) => s.status,
        'status',
        status,
      );
      if (messages != null) {
        m = m.having((s) => s.messages, 'messages', messages);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    OutreachMessageBloc build() => OutreachMessageBloc(restClient);

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageLoad_campaign_loadsFirstPage',
      setUp: () =>
          when(
            () => restClient.listOutreachMessages(
              start: 0,
              limit: 20,
              marketingCampaignId: 'C1',
            ),
          ).thenAnswer(
            (_) async => const OutreachMessages(messages: [pending, failed]),
          ),
      build: build,
      act: (bloc) => bloc.add(const OutreachMessageLoad(campaignId: 'C1')),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        msgState(OutreachMessageStatus.loading, messages: []),
        msgState(OutreachMessageStatus.success, messages: [pending, failed]),
      ],
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageLoad_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.listOutreachMessages(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const OutreachMessageLoad()),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        msgState(OutreachMessageStatus.loading),
        msgState(OutreachMessageStatus.failure, message: 'No access'),
      ],
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageCreate_message_insertsFirst',
      setUp: () => when(
        () => restClient.createOutreachMessage(
          marketingCampaignId: 'C1',
          platform: 'EMAIL',
          recipientEmail: 'jane@x.com',
          messageContent: 'Hi',
        ),
      ).thenAnswer((_) async => failed),
      build: build,
      seed: () => const OutreachMessageState(messages: [pending]),
      act: (bloc) => bloc.add(
        const OutreachMessageCreate(
          campaignId: 'C1',
          platform: 'EMAIL',
          recipientEmail: 'jane@x.com',
          messageContent: 'Hi',
        ),
      ),
      expect: () => [
        msgState(OutreachMessageStatus.loading),
        msgState(OutreachMessageStatus.success, messages: [failed, pending]),
      ],
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageUpdateStatus_withContent_savesContentThenStatus',
      setUp: () {
        when(
          () => restClient.updateOutreachMessageContent(
            messageId: 'M1',
            messageContent: 'Hello',
          ),
        ).thenAnswer((_) async => '{}');
        when(
          () => restClient.updateOutreachMessageStatus(
            messageId: 'M1',
            status: 'PENDING',
          ),
        ).thenAnswer(
          (_) async => const OutreachMessage(
            messageId: 'M1',
            platform: 'EMAIL',
            messageContent: 'Hello',
            status: 'PENDING',
          ),
        );
      },
      build: build,
      seed: () => const OutreachMessageState(messages: [pending]),
      act: (bloc) => bloc.add(
        const OutreachMessageUpdateStatus(
          messageId: 'M1',
          status: 'PENDING',
          messageContent: 'Hello',
        ),
      ),
      expect: () => [
        msgState(OutreachMessageStatus.loading),
        msgState(
          OutreachMessageStatus.success,
        ).having((s) => s.messages.single.messageContent, 'content', 'Hello'),
      ],
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageUpdateStatus_statusOnly_skipsContentEndpoint',
      setUp: () => when(
        () => restClient.updateOutreachMessageStatus(
          messageId: 'M2',
          status: 'PENDING',
        ),
      ).thenAnswer((_) async => pending),
      build: build,
      act: (bloc) => bloc.add(
        const OutreachMessageUpdateStatus(messageId: 'M2', status: 'PENDING'),
      ),
      verify: (_) => verifyNever(
        () => restClient.updateOutreachMessageContent(
          messageId: any(named: 'messageId'),
          messageContent: any(named: 'messageContent'),
        ),
      ),
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageDelete_message_removesIt',
      setUp: () => when(
        () => restClient.deleteOutreachMessage(messageId: 'M1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => const OutreachMessageState(messages: [pending, failed]),
      act: (bloc) => bloc.add(const OutreachMessageDelete('M1')),
      expect: () => [
        msgState(OutreachMessageStatus.loading),
        msgState(OutreachMessageStatus.success, messages: [failed]),
      ],
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageRetry_campaign_requeuesAndReloads',
      setUp: () {
        when(
          () => restClient.retryOutreachMessages(marketingCampaignId: 'C1'),
        ).thenAnswer((_) async => jsonEncode({'retriedCount': 3}));
        when(
          () => restClient.listOutreachMessages(
            start: 0,
            limit: 20,
            marketingCampaignId: 'C1',
          ),
        ).thenAnswer((_) async => const OutreachMessages(messages: [pending]));
      },
      build: build,
      act: (bloc) => bloc.add(const OutreachMessageRetry(campaignId: 'C1')),
      expect: () => [
        msgState(OutreachMessageStatus.loading),
        msgState(
          OutreachMessageStatus.success,
          messages: [pending],
          message: '3 message(s) requeued',
        ),
      ],
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageConvertToLead_prospect_createsLeadAndStampsMessage',
      setUp: () {
        when(
          () => restClient.createUser(user: any(named: 'user')),
        ).thenAnswer((_) async => User(partyId: 'L1'));
        when(
          () => restClient.updateOutreachMessageStatus(
            messageId: 'M1',
            status: 'CONVERTED',
            convertedPartyId: 'L1',
          ),
        ).thenAnswer(
          (_) async => const OutreachMessage(
            messageId: 'M1',
            platform: 'EMAIL',
            messageContent: 'Hi',
            status: 'CONVERTED',
          ),
        );
      },
      build: build,
      seed: () => const OutreachMessageState(messages: [pending]),
      act: (bloc) => bloc.add(
        const OutreachMessageConvertToLead(
          messageId: 'M1',
          firstName: 'Jane',
          email: 'jane@x.com',
          companyName: 'Acme',
        ),
      ),
      expect: () => [
        msgState(OutreachMessageStatus.loading),
        msgState(
          OutreachMessageStatus.success,
          message: 'Prospect converted to lead (L1)',
        ).having((s) => s.messages.single.status, 'status', 'CONVERTED'),
      ],
      verify: (_) {
        final lead =
            verify(
                  () => restClient.createUser(user: captureAny(named: 'user')),
                ).captured.single
                as User;
        expect(lead.role, Role.lead);
        expect(lead.company?.name, 'Acme');
        expect(lead.loginName, 'jane@x.com');
      },
    );

    blocTest<OutreachMessageBloc, OutreachMessageState>(
      'OutreachMessageSearchRequested_query_setsSearchResults',
      setUp: () => when(
        () =>
            restClient.listOutreachMessages(start: 0, limit: 50, search: 'jan'),
      ).thenAnswer((_) async => const OutreachMessages(messages: [pending])),
      build: build,
      act: (bloc) =>
          bloc.add(const OutreachMessageSearchRequested(query: 'jan')),
      wait: const Duration(milliseconds: 400),
      verify: (bloc) {
        expect(bloc.state.searchStatus, OutreachMessageStatus.success);
        expect(bloc.state.searchResults, [pending]);
      },
    );
  });

  group('PlatformConfigBloc', () {
    const email = PlatformConfiguration(configId: 'P1', platform: 'EMAIL');
    const linkedin = PlatformConfiguration(
      configId: 'P2',
      platform: 'LINKEDIN',
    );

    TypeMatcher<PlatformConfigState> configState(
      PlatformConfigStatus status, {
      List<PlatformConfiguration>? configs,
      String? message,
    }) {
      var m = isA<PlatformConfigState>().having(
        (s) => s.status,
        'status',
        status,
      );
      if (configs != null) m = m.having((s) => s.configs, 'configs', configs);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    PlatformConfigBloc build() => PlatformConfigBloc(restClient);

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigFetch_any_listsConfigs',
      setUp: () =>
          when(() => restClient.listPlatformConfigurations()).thenAnswer(
            (_) async =>
                const PlatformConfigurations(configs: [email, linkedin]),
          ),
      build: build,
      act: (bloc) => bloc.add(const PlatformConfigFetch()),
      expect: () => [
        configState(PlatformConfigStatus.loading),
        configState(PlatformConfigStatus.success, configs: [email, linkedin]),
      ],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigCreate_enabled_sendsYAndAppends',
      setUp: () => when(
        () => restClient.createPlatformConfiguration(
          platform: 'LINKEDIN',
          isEnabled: 'Y',
          dailyLimit: 50,
        ),
      ).thenAnswer((_) async => linkedin),
      build: build,
      seed: () => const PlatformConfigState(configs: [email]),
      act: (bloc) => bloc.add(
        const PlatformConfigCreate(
          PlatformConfiguration(platform: 'LINKEDIN', isEnabled: true),
        ),
      ),
      expect: () => [
        configState(PlatformConfigStatus.loading),
        configState(PlatformConfigStatus.success, configs: [email, linkedin]),
      ],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigUpdate_disabled_sendsNAndReplaces',
      setUp: () => when(
        () => restClient.updatePlatformConfiguration(
          configId: 'P1',
          isEnabled: 'N',
          dailyLimit: 50,
        ),
      ).thenAnswer((_) async => email),
      build: build,
      seed: () => const PlatformConfigState(configs: [email, linkedin]),
      act: (bloc) => bloc.add(const PlatformConfigUpdate(email)),
      expect: () => [
        configState(PlatformConfigStatus.loading),
        configState(PlatformConfigStatus.success, configs: [email, linkedin]),
      ],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigVerify_withScreenValues_savesProbesAndReloads',
      setUp: () {
        when(
          () => restClient.updatePlatformConfiguration(
            configId: 'P1',
            isEnabled: 'N',
            dailyLimit: 50,
          ),
        ).thenAnswer((_) async => email);
        when(
          () => restClient.verifyPlatformConfiguration(configId: 'P1'),
        ).thenAnswer((_) async => jsonEncode({'message': 'SMTP login ok'}));
        when(() => restClient.listPlatformConfigurations()).thenAnswer(
          (_) async => const PlatformConfigurations(configs: [email]),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const PlatformConfigVerify('P1', config: email)),
      expect: () => [
        configState(PlatformConfigStatus.loading),
        configState(
          PlatformConfigStatus.verified,
          configs: [email],
          message: 'SMTP login ok',
        ),
      ],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigDelete_config_removesWithoutMessage',
      setUp: () => when(
        () => restClient.deletePlatformConfiguration(configId: 'P2'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => const PlatformConfigState(configs: [email, linkedin]),
      act: (bloc) => bloc.add(const PlatformConfigDelete('P2')),
      expect: () => [
        configState(PlatformConfigStatus.loading),
        configState(
          PlatformConfigStatus.success,
          configs: [email],
        ).having((s) => s.message, 'message', isNull),
      ],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.listPlatformConfigurations(),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const PlatformConfigFetch()),
      expect: () => [
        configState(PlatformConfigStatus.loading),
        configState(PlatformConfigStatus.failure),
      ],
    );

    final connected = PlatformConfiguration(
      configId: 'P2',
      platform: 'LINKEDIN',
      apiKey: 'token',
      username: 'urn:li:person:AbC',
      apiKeyExpireDate: DateTime.utc(2027, 1, 1),
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigLinkedInConnect_any_emitsWaitingWithAuthUrl',
      setUp: () => when(() => restClient.startLinkedInSignIn()).thenAnswer(
        (_) async => jsonEncode({'authUrl': 'https://www.linkedin.com/x'}),
      ),
      build: build,
      act: (bloc) => bloc.add(const PlatformConfigLinkedInConnect()),
      expect: () => [
        configState(
          PlatformConfigStatus.linkedInWaiting,
        ).having((s) => s.authUrl, 'authUrl', 'https://www.linkedin.com/x'),
      ],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigLinkedInConnect_notConfigured_emitsFailure',
      setUp: () => when(
        () => restClient.startLinkedInSignIn(),
      ).thenThrow(Exception('LinkedIn connect not available')),
      build: build,
      act: (bloc) => bloc.add(const PlatformConfigLinkedInConnect()),
      expect: () => [
        configState(PlatformConfigStatus.failure).having(
          (s) => s.message,
          'message',
          contains('LinkedIn connect not available'),
        ),
      ],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigLinkedInCheck_tokenUnchanged_emitsNothing',
      setUp: () {
        when(
          () => restClient.startLinkedInSignIn(),
        ).thenAnswer((_) async => {'authUrl': 'https://www.linkedin.com/x'});
        when(() => restClient.listPlatformConfigurations()).thenAnswer(
          (_) async => PlatformConfigurations(configs: [email, connected]),
        );
      },
      build: build,
      seed: () => PlatformConfigState(configs: [email, connected]),
      act: (bloc) async {
        bloc.add(const PlatformConfigLinkedInConnect());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PlatformConfigLinkedInCheck());
      },
      expect: () => [configState(PlatformConfigStatus.linkedInWaiting)],
    );

    blocTest<PlatformConfigBloc, PlatformConfigState>(
      'PlatformConfigLinkedInCheck_newToken_emitsConnected',
      setUp: () {
        when(
          () => restClient.startLinkedInSignIn(),
        ).thenAnswer((_) async => {'authUrl': 'https://www.linkedin.com/x'});
        when(() => restClient.listPlatformConfigurations()).thenAnswer(
          (_) async => PlatformConfigurations(configs: [email, connected]),
        );
      },
      build: build,
      seed: () => const PlatformConfigState(configs: [email, linkedin]),
      act: (bloc) async {
        bloc.add(const PlatformConfigLinkedInConnect());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PlatformConfigLinkedInCheck());
      },
      expect: () => [
        configState(PlatformConfigStatus.linkedInWaiting),
        configState(
          PlatformConfigStatus.linkedInConnected,
          configs: [email, connected],
          message: 'LinkedIn connected',
        ),
      ],
    );
  });
}
