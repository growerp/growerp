import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import '../services/campaign_automation_service.dart';

part 'outreach_campaign_event.dart';
part 'outreach_campaign_state.dart';

class OutreachCampaignBloc
    extends Bloc<OutreachCampaignEvent, OutreachCampaignState> {
  OutreachCampaignBloc(this.restClient,
      {CampaignAutomationService? automationService})
      : _automationService =
            automationService ?? CampaignAutomationService(restClient),
        super(const OutreachCampaignState()) {
    on<OutreachCampaignFetch>(_onFetch);
    on<OutreachCampaignCreate>(_onCreate);
    on<OutreachCampaignUpdate>(_onUpdate);
    on<OutreachCampaignDelete>(_onDelete);
    on<OutreachCampaignDetailFetch>(_onDetailFetch);
    on<OutreachCampaignPause>(_onPause);
    on<OutreachCampaignStart>(_onStart);
    on<OutreachRecentMessagesFetch>(_onRecentMessagesFetch);
    on<OutreachCampaignSearchRequested>(_onSearch);
  }

  final RestClient restClient;
  final CampaignAutomationService _automationService;

  Future<void> _onFetch(
    OutreachCampaignFetch event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    if (state.hasReachedMax && event.start > 0) return;

    try {
      if (event.start == 0) {
        emit(state.copyWith(
          status: OutreachCampaignStatus.loading,
          campaigns: [],
          hasReachedMax: false,
        ));
      }

      final result = await restClient.listOutreachCampaigns(
        status: event.status,
        start: event.start,
        limit: event.limit,
      );

      final campaigns = event.start == 0
          ? List<OutreachCampaign>.from(result.campaigns)
          : (List<OutreachCampaign>.from(state.campaigns)
            ..addAll(result.campaigns));

      emit(state.copyWith(
        status: OutreachCampaignStatus.success,
        campaigns: campaigns,
        hasReachedMax: result.campaigns.length < event.limit,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: OutreachCampaignStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onCreate(
    OutreachCampaignCreate event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    try {
      await restClient.createOutreachCampaign(
        campaign: {
          'campaignName': event.name,
          'platforms': event.platforms,
          'targetAudience': event.targetAudience,
          'landingPageId': event.landingPageId,
          'messageTemplate': event.messageTemplate,
          'emailSubject': event.emailSubject,
          'platformSettings': event.platformSettings,
          'dailyLimitPerPlatform': event.dailyLimitPerPlatform,
        },
      );

      // Refresh list
      final result = await restClient.listOutreachCampaigns();
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.success,
          campaigns: result.campaigns,
          message: 'Campaign created successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    OutreachCampaignUpdate event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    // Emit loading to ensure state change is detected on repeated updates
    emit(state.copyWith(status: OutreachCampaignStatus.loading));
    try {
      await restClient.updateOutreachCampaign(
        campaign: {
          'marketingCampaignId': event.campaignId,
          'pseudoId': event.pseudoId,
          'campaignName': event.name,
          'platforms': event.platforms,
          'targetAudience': event.targetAudience,
          'landingPageId': event.landingPageId,
          'messageTemplate': event.messageTemplate,
          'emailSubject': event.emailSubject,
          'platformSettings': event.platformSettings,
          'statusId': event.status,
          'dailyLimitPerPlatform': event.dailyLimitPerPlatform,
        },
      );

      // Refresh list
      final result = await restClient.listOutreachCampaigns();
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.success,
          campaigns: result.campaigns,
          message: 'Campaign updated successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onDelete(
    OutreachCampaignDelete event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    try {
      await restClient.deleteOutreachCampaign(
          marketingCampaignId: event.campaignId);

      // Refresh list
      final result = await restClient.listOutreachCampaigns();
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.success,
          campaigns: result.campaigns,
          message: 'Campaign deleted successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onDetailFetch(
    OutreachCampaignDetailFetch event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    emit(state.copyWith(status: OutreachCampaignStatus.loading));
    try {
      final detail = await restClient.getOutreachCampaignDetail(
        marketingCampaignId: event.campaignId,
        pseudoId: event.pseudoId,
      );
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.success,
          selectedCampaign: detail.campaign,
          messages: detail.messages,
          metrics: detail.metrics,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onPause(
    OutreachCampaignPause event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    try {
      // Stop local automation first
      await _automationService.pauseCampaign(event.campaignId);

      // Refresh list (backend status already updated by pauseCampaign)
      final result = await restClient.listOutreachCampaigns();
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.success,
          campaigns: result.campaigns,
          message: 'Campaign paused',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onStart(
    OutreachCampaignStart event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    try {
      // Find campaign from state
      OutreachCampaign? campaign;
      for (final c in state.campaigns) {
        if (c.campaignId == event.campaignId) {
          campaign = c;
          break;
        }
      }

      // If not found in state, fetch from backend
      if (campaign == null) {
        final detail = await restClient.getOutreachCampaignDetail(
          marketingCampaignId: event.campaignId,
        );
        campaign = detail.campaign;
      }

      // Start local automation (this also notifies backend)
      // Run in background - don't await the full automation
      _automationService.startCampaign(campaign);

      // Refresh list
      final result = await restClient.listOutreachCampaigns();
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.success,
          campaigns: result.campaigns,
          message: 'Campaign started',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onRecentMessagesFetch(
    OutreachRecentMessagesFetch event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    try {
      final result = await restClient.listOutreachMessages(
        limit: event.limit,
      );
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.success,
          messages: result.messages,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachCampaignStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onSearch(
    OutreachCampaignSearchRequested event,
    Emitter<OutreachCampaignState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        searchStatus: OutreachCampaignStatus.success,
        searchResults: const [],
        searchError: null,
      ));
      return;
    }

    emit(state.copyWith(
      searchStatus: OutreachCampaignStatus.loading,
      searchResults: const [],
      searchError: null,
    ));

    try {
      final result = await restClient.listOutreachCampaigns(
        start: 0,
        limit: event.limit,
        searchString: query,
      );

      emit(state.copyWith(
        searchStatus: OutreachCampaignStatus.success,
        searchResults: result.campaigns,
        searchError: null,
      ));
    } catch (error) {
      emit(state.copyWith(
        searchStatus: OutreachCampaignStatus.failure,
        searchResults: const [],
        searchError: await getDioError(error),
      ));
    }
  }
}
