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
import 'models.dart';

part 'authenticate_model.freezed.dart';
part 'authenticate_model.g.dart';

@freezed
abstract class Authenticate with _$Authenticate {
  Authenticate._();
  factory Authenticate({
    final String? apiKey, // api or actions as changePassword, moreinfo
    final String? loginStatus, // e.g. passwordChange, setupRequired, registered, etc.
    String? applicationId, // appname
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
