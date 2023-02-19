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
import 'package:flutter/foundation.dart';
import 'package:growerp_core/growerp_core.dart';

class UserCompanyAPIRepository extends APIRepository {
  UserCompanyAPIRepository(super.apiKey);

  Future<ApiResult<List<User>>> getUser(
      {int? start,
      int? limit,
      Role? role,
      String? userPartyId,
      String? filter,
      String? searchString}) async {
    try {
      final response = await dioClient.get('rest/s1/growerp/100/User', apiKey!,
          queryParameters: <String, dynamic>{
            'userPartyId': userPartyId,
            'role': role,
            'filter': filter,
            'start': start,
            'limit': limit,
            'search': searchString
          });
      return getResponseList<User>(
          "users", response, (json) => User.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  // for ecommerce
  Future<ApiResult<User>> registerUser(User user, String ownerPartyId) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/RegisterUser', apiKey!,
          data: <String, dynamic>{
            'user': jsonEncode(user.toJson()),
            'moquiSessionToken': sessionToken,
            'classificationId': classificationId,
            'ownerPartyId': ownerPartyId,
            'password': kReleaseMode ? null : 'qqqqqq9!',
          });
      return getResponse<User>("user", response, (json) => User.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<User>> createUser(User user) async {
    try {
      final response = await dioClient
          .post('rest/s1/growerp/100/User', apiKey!, data: <String, dynamic>{
        'user': jsonEncode(user.toJson()),
        'password': kDebugMode ? 'qqqqqq9!' : null,
        'moquiSessionToken': sessionToken
      });
      return getResponse<User>("user", response, (json) => User.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Company>>> getCompanies(
      {bool mainCompanies = true, // just owner organizations or all?
      int? start,
      int? limit,
      String? filter}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Companies', null,
          queryParameters: <String, dynamic>{
            'mainCompanies': mainCompanies.toString(),
            'start': start,
            'limit': limit,
            'filter': filter,
          });
      return getResponseList<Company>(
          "companies", response, (json) => Company.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Company>> createCompany(Company company) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/Company', apiKey!, data: <String, dynamic>{
        'company': jsonEncode(company.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<Company>(
          "company", response, (json) => Company.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
