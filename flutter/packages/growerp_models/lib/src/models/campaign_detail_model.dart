import 'package:json_annotation/json_annotation.dart';
import 'outreach_campaign_model.dart';
import 'outreach_message_model.dart';
import 'campaign_metrics_model.dart';

part 'campaign_detail_model.g.dart';

/// Campaign detail with nested data
@JsonSerializable(explicitToJson: true)
class CampaignDetail {
  final OutreachCampaign campaign;
  final List<OutreachMessage> messages;
  final CampaignMetrics? metrics;

  const CampaignDetail({
    required this.campaign,
    this.messages = const [],
    this.metrics,
  });

  factory CampaignDetail.fromJson(Map<String, dynamic> json) =>
      _$CampaignDetailFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignDetailToJson(this);
}
