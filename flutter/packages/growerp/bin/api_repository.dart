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
import 'package:dio/dio.dart';
import 'package:growerp_rest/growerp_rest.dart';
import 'package:growerp_models/growerp_models.dart';

class APIRepository {
  String? apiKey;
  String classificationId = 'app_admin';
  String? sessionToken;

  late DioClient dioClient;
  late String _baseUrl;

  APIRepository([this.apiKey]) {
    var dio = Dio();
    _baseUrl = 'http://localhost:8080/';

    dioClient = DioClient(_baseUrl, dio, interceptors: []);
  }

  /// Json model List decoding
  ApiResult<List<T>> getResponseList<T>(String name, String result,
      T Function(Map<String, dynamic> json) fromJson) {
    final l = json.decode(result)[name] as Iterable;
    return ApiResult.success(data: List<T>.from(l.map<T>(
        // ignore: avoid_as, avoid_annotating_with_dynamic
        (dynamic i) => fromJson(i as Map<String, dynamic>))));
  }

  /// Json model decoding
  ApiResult<T> getResponse<T>(String name, String result,
      T Function(Map<String, dynamic> json) fromJson) {
    return ApiResult.success(
        data: fromJson(json.decode(result)[name] as Map<String, dynamic>));
  }

  Future<ApiResult<bool>> getConnected() async {
    try {
      final response = await dioClient.get('growerp/moquiSessionToken', null);
      sessionToken = response.toString();
      return ApiResult.success(
          data: sessionToken != null); // return true if session token ok
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  void setApiKey(String apiKey, String sessionToken) {
    this.apiKey = apiKey;
    this.sessionToken = sessionToken;
  }

  Future<ApiResult<Authenticate>> getAuthenticate() async {
    try {
      final response =
          await dioClient.get('rest/s1/growerp/100/Authenticate', apiKey!);
      return getResponse<Authenticate>(
          "authenticate", response, (json) => Authenticate.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<bool>> upLoadEntities(
    Map entities,
  ) async {
    try {
      final response = await dioClient.post(
        'rest/s1/growerp/100/ImportExport',
        apiKey,
        data: <String, dynamic>{
          'entities': entities,
          'classificationId': classificationId,
          'moquiSessionToken': sessionToken,
        },
      );
      return ApiResult.success(
          data: jsonDecode(response.toString())['ok'] == 'ok');
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<bool>> checkCompany(String partyId) async {
    try {
      // no apykey required, if not valid will report no company
      final response = await dioClient.get(
          'rest/s1/growerp/100/CheckCompany', null,
          queryParameters: <String, dynamic>{'partyId': partyId});
      return ApiResult.success(
          data: jsonDecode(response.toString())['ok'] == 'ok');
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<bool>> checkEmail(String email) async {
    try {
      // no apykey required, if not valid will report no email address
      final response = await dioClient.get(
          'rest/s1/growerp/100/CheckEmail', null,
          queryParameters: <String, dynamic>{'email': email});
      return ApiResult.success(
          data: jsonDecode(response.toString())['ok'] == 'ok');
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  /// The demo store can only register as a customer.
  /// Any other store it depends on the person logging in.
  Future<ApiResult<Authenticate>> register({
    required String companyName,
    required String firstName,
    required String lastName,
    required String currencyId,
    required String email,
    bool demoData = true,
  }) async {
    try {
      final response = await dioClient.post(
        'rest/s1/growerp/100/UserAndCompany',
        null,
        data: <String, dynamic>{
          'username': email,
          'emailAddress': email,
          'newPassword': 'qqqqqq9!',
          'firstName': firstName,
          'lastName': lastName,
          'companyName': companyName,
//          'locale': locale,
          'currencyId': currencyId,
          'companyEmailAddress': email,
          'classificationId': classificationId,
          'moquiSessionToken': sessionToken,
          'demoData': demoData.toString()
        },
      );
      return getResponse<Authenticate>(
          "authenticate", response, (json) => Authenticate.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Authenticate>> login(
      {required String username, required String password}) async {
    try {
      final response = await dioClient
          .post('rest/s1/growerp/100/Login', null, data: <String, dynamic>{
        'username': username,
        'password': password,
        'moquiSessionToken': sessionToken,
        'classificationId': classificationId,
      });
      return getResponse<Authenticate>(
          "authenticate", response, (json) => Authenticate.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<void>> resetPassword({required String username}) async {
    try {
      await dioClient.post('rest/s1/growerp/100/ResetPassword', null,
          data: <String, dynamic>{
            'username': username,
            'moquiSessionToken': sessionToken
          });
      return const ApiResult.success(data: null);
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Authenticate>> updatePassword(
      {required String username,
      required String oldPassword,
      required String newPassword}) async {
    try {
      final response = await dioClient
          .post('rest/s1/growerp/100/Password', null, data: <String, dynamic>{
        'username': username,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'moquiSessionToken': sessionToken
      });
      return getResponse<Authenticate>(
          "authenticate", response, (json) => Authenticate.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<String>> logout() async {
    try {
      final response = await dioClient.post('growerp/logout', apiKey!);
      return ApiResult.success(data: response);
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
