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

import 'package:json_annotation/json_annotation.dart';

part 'campaign_progress_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CampaignProgress {
  final String campaignId;
  final String status;
  final int messagesSent;
  final int messagesPending;
  final int messagesFailed;
  final int responsesReceived;
  final double responseRate;

  CampaignProgress({
    required this.campaignId,
    required this.status,
    this.messagesSent = 0,
    this.messagesPending = 0,
    this.messagesFailed = 0,
    this.responsesReceived = 0,
    this.responseRate = 0.0,
  });

  factory CampaignProgress.fromJson(Map<String, dynamic> json) =>
      _$CampaignProgressFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignProgressToJson(this);
}
