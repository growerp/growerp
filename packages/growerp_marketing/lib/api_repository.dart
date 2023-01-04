import 'dart:convert';

import 'package:global_configuration/global_configuration.dart';
import 'package:core/services/api_result.dart';
import 'package:core/services/network_exceptions.dart';
import 'package:core/api_repository.dart';
import 'opportunities/models/models.dart';

class Marketing_APIRepository extends APIRepository {
  String? apiKey;

  Marketing_APIRepository(this.apiKey) : super() {}

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
