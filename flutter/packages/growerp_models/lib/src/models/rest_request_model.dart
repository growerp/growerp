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
import 'package:growerp_models/src/json_converters.dart';
import 'models.dart';

part 'rest_request_model.freezed.dart';
part 'rest_request_model.g.dart';

@freezed
abstract class RestRequest with _$RestRequest {
  RestRequest._();
  factory RestRequest({
    User? user,
    String? companyName,
    @DateTimeConverter() DateTime? dateTime,
    String? restRequestName,
    String? serverIp,
    String? serverHostName,
    String? parameterString,
    bool? wasError,
    String? errorMessage,
    String? requestUrl,
    String? referrerUrl,
    bool? isSlowHit,
    int? runningTimeMillis,
  }) = _RestRequest;

  factory RestRequest.fromJson(Map<String, dynamic> json) =>
      _$RestRequestFromJson(json["restRequest"] ?? json);

  @override
  String toString() =>
      'User name: ${user!.firstName} ${user!.lastName} '
      'Request name: $restRequestName ';
}
