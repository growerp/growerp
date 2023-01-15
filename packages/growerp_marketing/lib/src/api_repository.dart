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
import 'opportunities/models/models.dart';

class MarketingAPIRepository extends APIRepository {
  String? apiKey;

  MarketingAPIRepository(this.apiKey) : super() {}

  Future<ApiResult<List<Opportunity>>> getOpportunity({
    int? start,
    int? limit,
    String? opportunityId,
    bool? my,
    String? searchString,
  }) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Opportunity', apiKey!,
          queryParameters: <String, dynamic>{
            'opportunityId': opportunityId,
            'start': start,
            'limit': limit,
            'my': my.toString(),
            'search': searchString
          });
      return getResponseList<Opportunity>(
          "opportunities", response, (json) => Opportunity.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Opportunity>> createOpportunity(
      Opportunity opportunity) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/Opportunity', apiKey!,
          data: <String, dynamic>{
            'opportunity': jsonEncode(opportunity.toJson()),
            'moquiSessionToken': sessionToken
          });
      return getResponse<Opportunity>(
          "opportunity", response, (json) => Opportunity.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Opportunity>> updateOpportunity(
      Opportunity opportunity) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Opportunity', apiKey!,
          data: <String, dynamic>{
            'opportunity': jsonEncode(opportunity.toJson()),
            'moquiSessionToken': sessionToken
          });
      return getResponse<Opportunity>(
          "opportunity", response, (json) => Opportunity.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Opportunity>> deleteOpportunity(
      Opportunity opportunity) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/Opportunity', apiKey!,
          queryParameters: <String, dynamic>{
            'opportunity': jsonEncode(opportunity.toJson()),
          });
      return getResponse<Opportunity>(
          "opportunity", response, (json) => Opportunity.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
