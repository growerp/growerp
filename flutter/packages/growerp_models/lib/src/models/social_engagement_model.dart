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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

part 'social_engagement_model.freezed.dart';
part 'social_engagement_model.g.dart';

@freezed
abstract class SocialEngagement with _$SocialEngagement {
  SocialEngagement._();
  factory SocialEngagement({
    @Default("") String engagementId,
    @Default("") String postId,
    @Default("") String platform,
    @Default("") String engagementType, // LIKE, COMMENT, SHARE, DM_REPLY
    @Default("") String userName,
    @Default("") String userProfileUrl,
    @Default("") String note,
    @Default("") String status, // NEW, CONTACTED, CONVERTED
    @DateTimeConverter() DateTime? createdDate,
  }) = _SocialEngagement;

  factory SocialEngagement.fromJson(Map<String, dynamic> json) =>
      _$SocialEngagementFromJson(json['socialEngagement'] ?? json);
}

@freezed
abstract class SocialEngagements with _$SocialEngagements {
  SocialEngagements._();
  factory SocialEngagements({
    @Default([]) List<SocialEngagement> socialEngagements,
  }) = _SocialEngagements;

  factory SocialEngagements.fromJson(Map<String, dynamic> json) =>
      _$SocialEngagementsFromJson(json);
}
