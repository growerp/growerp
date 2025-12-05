import 'package:json_annotation/json_annotation.dart';

part 'campaign_metrics_model.g.dart';

/// Campaign Metrics model
@JsonSerializable()
class CampaignMetrics {
  /// Metric unique identifier
  final String? metricId;

  /// Parent campaign ID
  final String? campaignId;

  /// Total messages sent
  final int messagesSent;

  /// Total messages pending
  final int messagesPending;

  /// Total messages failed
  final int messagesFailed;

  /// Total responses received
  final int responsesReceived;

  /// Total leads generated via landing page
  final int leadsGenerated;

  /// Last update timestamp
  final DateTime? lastUpdated;

  /// Response rate percentage (calculated)
  final double? responseRate;

  /// Conversion rate percentage (calculated)
  final double? conversionRate;

  const CampaignMetrics({
    this.metricId,
    this.campaignId,
    this.messagesSent = 0,
    this.messagesPending = 0,
    this.messagesFailed = 0,
    this.responsesReceived = 0,
    this.leadsGenerated = 0,
    this.lastUpdated,
    this.responseRate,
    this.conversionRate,
  });

  factory CampaignMetrics.fromJson(Map<String, dynamic> json) =>
      _$CampaignMetricsFromJson(json['metrics'] ?? json);

  Map<String, dynamic> toJson() => _$CampaignMetricsToJson(this);

  @override
  String toString() =>
      'CampaignMetrics(sent: $messagesSent, pending: $messagesPending, failed: $messagesFailed, responses: $responsesReceived, leads: $leadsGenerated)';
}
