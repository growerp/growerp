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
import 'package:core/domains/domains.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

@freezed
class Location with _$Location {
  factory Location({
    final String? locationId,
    final String? locationName,
    final List<Asset>? assets,
  }) = _Location;
  Location._();

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}
