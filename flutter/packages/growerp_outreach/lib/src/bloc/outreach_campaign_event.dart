part of 'outreach_campaign_bloc.dart';

abstract class OutreachCampaignEvent extends Equatable {
  const OutreachCampaignEvent();
  @override
  List<Object?> get props => [];
}

class OutreachCampaignFetch extends OutreachCampaignEvent {
  const OutreachCampaignFetch({
    this.status,
    this.start = 0,
    this.limit = 20,
    this.searchString,
  });

  final String? status;
  final int start;
  final int limit;
  final String? searchString;

  @override
  List<Object?> get props => [status, start, limit, searchString];
}

class OutreachCampaignCreate extends OutreachCampaignEvent {
  const OutreachCampaignCreate({
    required this.name,
    required this.platforms,
    this.description,
    this.targetAudience,
    this.landingPageId,
    this.messageTemplate,
    this.emailSubject,
    this.platformSettings,
    this.dailyLimitPerPlatform = 50,
    this.sendFromHour,
    this.sendToHour,
  });

  final String name;
  final String platforms;
  final String? description;
  final String? targetAudience;
  final String? landingPageId;
  final String? messageTemplate;
  final String? emailSubject;
  final String? platformSettings;
  final int dailyLimitPerPlatform;

  /// send window in UTC hours, null = no restriction
  final int? sendFromHour;
  final int? sendToHour;

  @override
  List<Object?> get props => [
        name,
        platforms,
        description,
        targetAudience,
        landingPageId,
        messageTemplate,
        emailSubject,
        platformSettings,
        dailyLimitPerPlatform,
        sendFromHour,
        sendToHour,
      ];
}

class OutreachCampaignUpdate extends OutreachCampaignEvent {
  const OutreachCampaignUpdate({
    required this.campaignId,
    this.pseudoId,
    this.name,
    this.description,
    this.platforms,
    this.targetAudience,
    this.landingPageId,
    this.messageTemplate,
    this.emailSubject,
    this.platformSettings,
    this.status,
    this.dailyLimitPerPlatform,
    this.sendFromHour,
    this.sendToHour,
  });

  final String campaignId;
  final String? pseudoId;
  final String? name;
  final String? description;
  final String? platforms;
  final String? targetAudience;
  final String? landingPageId;
  final String? messageTemplate;
  final String? emailSubject;
  final String? platformSettings;
  final String? status;
  final int? dailyLimitPerPlatform;

  /// send window in UTC hours, null leaves the stored value untouched
  final int? sendFromHour;
  final int? sendToHour;

  @override
  List<Object?> get props => [
        campaignId,
        pseudoId,
        name,
        description,
        platforms,
        targetAudience,
        landingPageId,
        messageTemplate,
        emailSubject,
        platformSettings,
        status,
        dailyLimitPerPlatform,
        sendFromHour,
        sendToHour,
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

/// Triggers the backend to publish all READY social posts whose scheduled
/// time has arrived. Fire-and-forget: errors are silently logged per post.
class OutreachPublishScheduledSocialPosts extends OutreachCampaignEvent {
  const OutreachPublishScheduledSocialPosts();
}

/// Ask the backend to build a complete campaign with AI from a short goal
/// description. The campaign is created server side and returned.
class OutreachCampaignGenerateWithAI extends OutreachCampaignEvent {
  const OutreachCampaignGenerateWithAI({
    required this.campaignGoal,
    this.targetAudience,
    this.platforms,
  });

  final String campaignGoal;
  final String? targetAudience;

  /// comma separated platform names, e.g. 'EMAIL,LINKEDIN'
  final String? platforms;

  @override
  List<Object?> get props => [campaignGoal, targetAudience, platforms];
}
