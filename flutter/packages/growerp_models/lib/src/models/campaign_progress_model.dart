/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
