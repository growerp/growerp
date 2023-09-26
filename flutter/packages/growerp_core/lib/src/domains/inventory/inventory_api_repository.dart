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

import 'dart:convert';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_rest/growerp_rest.dart';

class InventoryAPIRepository extends APIRepository {
  InventoryAPIRepository(super.apiKey);
  Future<ApiResult<List<Location>>> getLocation(
      {int? start,
      int? limit,
      String? locationId,
      String? filter,
      String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Location', apiKey!,
          queryParameters: <String, dynamic>{
            'start': start,
            'limit': limit,
            'filter': filter,
            'search': searchString,
          });
      return getResponseList<Location>(
          "locations", response, (json) => Location.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Location>> createLocation(Location location) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/Location', apiKey!, data: <String, dynamic>{
        'location': jsonEncode(location.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<Location>(
          "location", response, (json) => Location.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Location>> updateLocation(Location location) async {
    // no categoryId is add
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Location', apiKey!, data: <String, dynamic>{
        'location': jsonEncode(location.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<Location>(
          "location", response, (json) => Location.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Location>> deleteLocation(Location location) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/Location', apiKey!,
          queryParameters: <String, dynamic>{
            'location': jsonEncode(location.toJson()),
          });
      return getResponse<Location>(
          "location", response, (json) => Location.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
