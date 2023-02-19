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
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/src/domains/models/category_model.dart' as cat;
import 'services/api_result.dart';
import 'services/dio_client.dart';
import 'services/network_exceptions.dart';
import 'dart:io' show Platform;
import 'domains/domains.dart';

class APIRepository {
  String? apiKey;
  String classificationId = GlobalConfiguration().get('classificationId');
  String databaseUrl = GlobalConfiguration().get('databaseUrl');
  String databaseUrlDebug = GlobalConfiguration().get('databaseUrlDebug');
  String? sessionToken;

  late DioClient dioClient;
  late String _baseUrl;

  bool restRequestLogs =
      GlobalConfiguration().getValue<bool>('restRequestLogs');
  bool restResponseLogs =
      GlobalConfiguration().getValue<bool>('restResponseLogs');
  int connectTimeoutProd =
      GlobalConfiguration().getValue<int>('connectTimeoutProd') * 1000;
  int receiveTimeoutProd =
      GlobalConfiguration().getValue<int>('receiveTimeoutProd') * 1000;
  int connectTimeoutTest =
      GlobalConfiguration().getValue<int>('connectTimeoutTest') * 1000;
  int receiveTimeoutTest =
      GlobalConfiguration().getValue<int>('receiveTimeoutTest') * 1000;

  APIRepository([this.apiKey]) {
    var dio = Dio();
    _baseUrl = kReleaseMode
        ? '$databaseUrl/'
        : databaseUrlDebug.isNotEmpty
            ? '$databaseUrlDebug/'
            : (kIsWeb || Platform.isIOS || Platform.isLinux)
                ? 'http://localHost:8080/'
                : 'http://10.0.2.2:8080/';

    debugPrint('Using base backend url: $_baseUrl');

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

  Future<ApiResult<List<ItemType>>> getItemTypes({required bool sales}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/ItemTypes', apiKey!,
          queryParameters: <String, dynamic>{
            'sales': sales,
          });
      return getResponseList<ItemType>(
          "itemTypes", response, (json) => ItemType.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<PaymentType>>> getPaymentTypes(
      {bool sales = true}) async {
    try {
      final response =
          await dioClient.get('rest/s1/growerp/100/PaymentTypes', apiKey!);
      return getResponseList<PaymentType>(
          "paymentTypes", response, (json) => PaymentType.fromJson(json));
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
          'newPassword': kReleaseMode ? null : 'qqqqqq9!',
          'firstName': firstName,
          'lastName': lastName,
          'companyName': companyName,
//          'locale': locale,
          'currencyId': currencyId,
          'companyEmailAddress': email,
          'classificationId': classificationId,
          'productionEnvironment': kReleaseMode.toString(),
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
      final response = await dioClient.post('rest/s1/growerp/100/Login', null,
          data: <String, dynamic>{
            'username': username,
            'password': password,
            'moquiSessionToken': sessionToken
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

  Future<ApiResult<Company>> updateCompany(Company company) async {
    try {
      final response = await dioClient.patch(
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

  Future<ApiResult<User>> updateUser(User user) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/User', apiKey!, data: <String, dynamic>{
        'user': jsonEncode(user.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<User>("user", response, (json) => User.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<User>> deleteUser(
      String partyId, bool deleteCompanyToo) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/User', apiKey!,
          queryParameters: <String, dynamic>{
            'partyId': partyId,
            'deleteCompanyToo': deleteCompanyToo,
          });
      return getResponse<User>("user", response, (json) => User.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<GlAccount>>> getGlAccount() async {
    try {
      final response =
          await dioClient.get('rest/s1/growerp/100/Ledger', apiKey!);
      return getResponseList<GlAccount>(
          "glAccountList", response, (json) => GlAccount.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<ChatRoom>>> getChatRooms(
      {int? start,
      int? limit,
      String? chatRoomName,
      String? userId,
      bool? isPrivate,
      String? searchString,
      String? filter}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/ChatRoom', apiKey!,
          queryParameters: <String, dynamic>{
            'chatRoomName': chatRoomName,
            'userId': userId,
            'start': start,
            'limit': limit,
            'isPrivate': isPrivate,
            'search': searchString,
            'filter': filter,
          });
      return getResponseList<ChatRoom>(
          "chatRooms", response, (json) => ChatRoom.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<ChatRoom>> getChatRoom({
    required String? chatRoomId,
  }) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/ChatRoom', apiKey!,
          queryParameters: <String, dynamic>{
            'chatRoomId': chatRoomId,
          });
      return getResponse<ChatRoom>(
          "chatRoom", response, (json) => ChatRoom.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<ChatRoom>> updateChatRoom(ChatRoom chatRoom) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/ChatRoom', apiKey!, data: <String, dynamic>{
        'chatRoom': jsonEncode(chatRoom.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<ChatRoom>(
          "chatRoom", response, (json) => ChatRoom.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<ChatRoom>> createChatRoom(ChatRoom chatRoom) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/ChatRoom', apiKey!, data: <String, dynamic>{
        'chatRoom': jsonEncode(chatRoom.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<ChatRoom>(
          "chatRoom", response, (json) => ChatRoom.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<ChatRoom>> deleteChatRoom(String chatRoomId) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/ChatRoom', apiKey!,
          queryParameters: <String, dynamic>{'chatRoomId': chatRoomId});
      //    return response.data["chatRoomId"];
      return getResponse<ChatRoom>(
          "chatRoom", response, (json) => ChatRoom.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<ChatMessage>>> getChatMessages(
      {String? chatRoomId,
      int? start,
      int? limit,
      String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/ChatMessage', apiKey!,
          queryParameters: <String, dynamic>{
            'chatRoomId': chatRoomId,
            'start': start,
            'limit': limit,
            'search': searchString,
          });
      return getResponseList<ChatMessage>(
          "chatMessages", response, (json) => ChatMessage.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Task>>> getTask({
    int? start,
    int? limit,
    String? taskId,
    bool? open,
    String? searchString,
  }) async {
    try {
      final response = await dioClient.get('rest/s1/growerp/100/Task', apiKey!,
          queryParameters: <String, dynamic>{
            'taskId': taskId,
            'start': start,
            'limit': limit,
            'open': open.toString(),
            'search': searchString
          });
      return getResponseList<Task>(
          "tasks", response, (json) => Task.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Task>> createTask(Task task) async {
    try {
      final response = await dioClient.post('rest/s1/growerp/100/Task', apiKey!,
          data: <String, dynamic>{
            'task': jsonEncode(taskToJson(task)),
            'moquiSessionToken': sessionToken
          });
      return getResponse<Task>("task", response, (json) => Task.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Task>> updateTask(Task task) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Task', apiKey!, data: <String, dynamic>{
        'task': jsonEncode(taskToJson(task)),
        'moquiSessionToken': sessionToken
      });
      return getResponse<Task>("task", response, (json) => Task.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<TimeEntry>> deleteTimeEntry(TimeEntry timeEntry) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/TimeEntry', apiKey!,
          queryParameters: <String, dynamic>{
            'timeEntry': jsonEncode(timeEntryToJson(timeEntry)),
            'moquiSessionToken': sessionToken
          });
      return getResponse<TimeEntry>(
          "timeEntry", response, (json) => TimeEntry.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<TimeEntry>> createTimeEntry(TimeEntry timeEntry) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/TimeEntry', apiKey!,
          data: <String, dynamic>{
            'timeEntry': jsonEncode(timeEntryToJson(timeEntry)),
            'moquiSessionToken': sessionToken
          });
      return getResponse<TimeEntry>(
          "timeEntry", response, (json) => TimeEntry.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<TimeEntry>> updateTimeEntry(TimeEntry timeEntry) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/TimeEntry', apiKey!,
          data: <String, dynamic>{
            'timeEntry': jsonEncode(timeEntryToJson(timeEntry)),
            'moquiSessionToken': sessionToken
          });
      return getResponse<TimeEntry>(
          "timeEntry", response, (json) => TimeEntry.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  // lookup entities for general use

  Future<ApiResult<List<User>>> lookUpUser(
      {Role? role, String? searchString}) async {
    try {
      final response = await dioClient.get('rest/s1/growerp/100/User', apiKey!,
          queryParameters: <String, dynamic>{
            'role': role,
            'filter': searchString
          });
      return getResponseList<User>(
          "users", response, (json) => User.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Company>>> lookUpCompany(
      {bool mainCompanies = true, // just owner organizations or all?
      String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Companies', null,
          queryParameters: <String, dynamic>{
            'mainCompanies': mainCompanies,
            'filter': searchString,
          });
      return getResponseList<Company>(
          "companies", response, (json) => Company.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Product>>> lookUpProduct(
      {String? companyPartyId,
      String? categoryId,
      String? productTypeId,
      String? assetClassId,
      String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Products', apiKey,
          queryParameters: <String, dynamic>{
            'companyPartyId': companyPartyId,
            'categoryId': categoryId,
            'productTypeId': productTypeId,
            'assetClassId': assetClassId,
            'filter': searchString
          });
      return getResponseList<Product>(
          "products", response, (json) => Product.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Asset>>> lookUpAsset(
      {String? assetClassId, String? searchString}) async {
    try {
      final response = await dioClient.get('rest/s1/growerp/100/Asset', apiKey!,
          queryParameters: <String, dynamic>{
            'assetClassId': assetClassId,
            'filer': searchString
          });
      return getResponseList<Asset>(
          "assets", response, (json) => Asset.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<cat.Category>>> lookUpCategory(
      {String? companyPartyId, String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Categories', apiKey,
          queryParameters: <String, dynamic>{
            'companyPartyId': companyPartyId,
            'filer': searchString,
            'classificationId': classificationId,
          });
      return getResponseList<cat.Category>(
          "categories", response, (json) => cat.Category.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
