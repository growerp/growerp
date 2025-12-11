/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:json_annotation/json_annotation.dart';

part 'rate_limit_check_model.g.dart';

/// Result of a rate limit check
@JsonSerializable()
class RateLimitCheck {
  final bool? allowed;
  final int? remainingActions;
  final DateTime? resetDate;

  const RateLimitCheck({this.allowed, this.remainingActions, this.resetDate});

  factory RateLimitCheck.fromJson(Map<String, dynamic> json) =>
      _$RateLimitCheckFromJson(json);

  Map<String, dynamic> toJson() => _$RateLimitCheckToJson(this);
}
