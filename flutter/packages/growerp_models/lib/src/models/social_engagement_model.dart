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
