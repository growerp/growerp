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

part 'application_model.freezed.dart';
part 'application_model.g.dart';

@freezed
abstract class Application with _$Application {
  factory Application({
    @Default("") String applicationId,
    String? version, // room, table etc
    String? backendUrl, // include room number/name
  }) = _Application;
  Application._();

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json['application'] ?? json);

  @override
  String toString() =>
      'Application: $applicationId '
      'Version: $version '
      'BackendUrl: $backendUrl ';
}
