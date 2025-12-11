part of 'outreach_campaign_bloc.dart';

abstract class OutreachCampaignEvent extends Equatable {
  const OutreachCampaignEvent();
  @override
  List<Object?> get props => [];
}

class OutreachCampaignFetch extends OutreachCampaignEvent {
  const OutreachCampaignFetch({this.status, this.start = 0, this.limit = 20});

  final String? status;
  final int start;
  final int limit;

  @override
  List<Object?> get props => [status, start, limit];
}

class OutreachCampaignCreate extends OutreachCampaignEvent {
  const OutreachCampaignCreate({
    required this.name,
    required this.platforms,
    this.targetAudience,
    this.landingPageId,
    this.messageTemplate,
    this.emailSubject,
    this.dailyLimitPerPlatform = 50,
  });

  final String name;
  final String platforms;
  final String? targetAudience;
  final String? landingPageId;
  final String? messageTemplate;
  final String? emailSubject;
  final int dailyLimitPerPlatform;

  @override
  List<Object?> get props => [
        name,
        platforms,
        targetAudience,
        landingPageId,
        messageTemplate,
        emailSubject,
        dailyLimitPerPlatform,
      ];
}

class OutreachCampaignUpdate extends OutreachCampaignEvent {
  const OutreachCampaignUpdate({
    required this.campaignId,
    this.pseudoId,
    this.name,
    this.platforms,
    this.targetAudience,
    this.landingPageId,
    this.messageTemplate,
    this.emailSubject,
    this.status,
    this.dailyLimitPerPlatform,
  });

  final String campaignId;
  final String? pseudoId;
  final String? name;
  final String? platforms;
  final String? targetAudience;
  final String? landingPageId;
  final String? messageTemplate;
  final String? emailSubject;
  final String? status;
  final int? dailyLimitPerPlatform;

  @override
  List<Object?> get props => [
        campaignId,
        pseudoId,
        name,
        platforms,
        targetAudience,
        landingPageId,
        messageTemplate,
        emailSubject,
        status,
        dailyLimitPerPlatform,
      ];
}

class OutreachCampaignDelete extends OutreachCampaignEvent {
  const OutreachCampaignDelete(this.campaignId);

  final String campaignId;

  @override
  List<Object> get props => [campaignId];
}

class OutreachCampaignDetailFetch extends OutreachCampaignEvent {
  const OutreachCampaignDetailFetch({this.campaignId, this.pseudoId});

  final String? campaignId;
  final String? pseudoId;

  @override
  List<Object?> get props => [campaignId, pseudoId];
}

class OutreachCampaignPause extends OutreachCampaignEvent {
  const OutreachCampaignPause(this.campaignId);

  final String campaignId;

  @override
  List<Object> get props => [campaignId];
}

class OutreachCampaignStart extends OutreachCampaignEvent {
  const OutreachCampaignStart(this.campaignId);

  final String campaignId;

  @override
  List<Object> get props => [campaignId];
}

class OutreachRecentMessagesFetch extends OutreachCampaignEvent {
  const OutreachRecentMessagesFetch({this.limit = 50});

  final int limit;

  @override
  List<Object> get props => [limit];
}

class OutreachCampaignSearchRequested extends OutreachCampaignEvent {
  const OutreachCampaignSearchRequested({required this.query, this.limit = 20});

  final String query;
  final int limit;

  @override
  List<Object> get props => [query, limit];
}
