import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

part 'outreach_campaign_event.dart';
part 'outreach_campaign_state.dart';

class OutreachCampaignBloc
    extends Bloc<OutreachCampaignEvent, OutreachCampaignState> {
  OutreachCampaignBloc(this.restClient) : super(const OutreachCampaignState()) {
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
          'name': event.name,
          'platforms': event.platforms,
          'targetAudience': event.targetAudience,
          'landingPageId': event.landingPageId,
          'messageTemplate': event.messageTemplate,
          'emailSubject': event.emailSubject,
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
    try {
      await restClient.updateOutreachCampaign(
        campaign: {
          'campaignId': event.campaignId,
          'pseudoId': event.pseudoId,
          'name': event.name,
          'platforms': event.platforms,
          'targetAudience': event.targetAudience,
          'landingPageId': event.landingPageId,
          'messageTemplate': event.messageTemplate,
          'emailSubject': event.emailSubject,
          'status': event.status,
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
      await restClient.deleteOutreachCampaign(campaignId: event.campaignId);

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
        campaignId: event.campaignId,
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
      await restClient.updateOutreachCampaign(
        campaign: {
          'campaignId': event.campaignId,
          'status': 'PAUSED',
        },
      );

      // Refresh list
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
      await restClient.updateOutreachCampaign(
        campaign: {
          'campaignId': event.campaignId,
          'status': 'ACTIVE',
        },
      );

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
