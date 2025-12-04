part of 'outreach_campaign_bloc.dart';

enum OutreachCampaignStatus { initial, loading, success, failure }

class OutreachCampaignState extends Equatable {
  const OutreachCampaignState({
    this.status = OutreachCampaignStatus.initial,
    this.campaigns = const [],
    this.selectedCampaign,
    this.messages = const [],
    this.metrics,
    this.message,
    this.hasReachedMax = false,
  });

  final OutreachCampaignStatus status;
  final List<OutreachCampaign> campaigns;
  final OutreachCampaign? selectedCampaign;
  final List<OutreachMessage> messages;
  final CampaignMetrics? metrics;
  final String? message;
  final bool hasReachedMax;

  OutreachCampaignState copyWith({
    OutreachCampaignStatus? status,
    List<OutreachCampaign>? campaigns,
    OutreachCampaign? selectedCampaign,
    List<OutreachMessage>? messages,
    CampaignMetrics? metrics,
    String? message,
    bool? hasReachedMax,
  }) {
    return OutreachCampaignState(
      status: status ?? this.status,
      campaigns: campaigns ?? this.campaigns,
      selectedCampaign: selectedCampaign ?? this.selectedCampaign,
      messages: messages ?? this.messages,
      metrics: metrics ?? this.metrics,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
        status,
        campaigns,
        selectedCampaign,
        messages,
        metrics,
        message,
        hasReachedMax,
      ];
}
