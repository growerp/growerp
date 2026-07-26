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
