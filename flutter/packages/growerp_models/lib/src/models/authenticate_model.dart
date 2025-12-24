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
import 'models.dart';

part 'authenticate_model.freezed.dart';
part 'authenticate_model.g.dart';

@freezed
abstract class Authenticate with _$Authenticate {
  Authenticate._();
  factory Authenticate({
    final String? apiKey, // api or actions as changePassword, moreinfo
    String? classificationId, // appname
    String? moquiSessionToken,
    String? ownerPartyId,
    CompanyUser? companyUser,
    Company? company,
    User? user,
    Stats? stats,
    int? evaluationDays, // evaluation period in days (from backend config)
    int? subscriptionDaysRemaining, // days until subscription expires
    String? subscriptionStatus, // 'active', 'trial', 'expired', 'none'
  }) = _Authenticate;

  factory Authenticate.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateFromJson(json['authenticate'] ?? json);

  @override
  String toString() => "CompName: ${company?.name}, Usr: ${user?.lastName}";
}
