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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:models/@models.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:global_configuration/global_configuration.dart';

class Moqui {
  final Dio client;
  String? sessionToken;
  String? prodUrl = GlobalConfiguration().get("prodUrl");
  String classificationId = GlobalConfiguration().get("classificationId");
  bool restRequestLogs =
      GlobalConfiguration().getValue<bool>("restRequestLogs");
  bool restResponseLogs =
      GlobalConfiguration().getValue<bool>("restResponseLogs");
  int connectTimeoutProd =
      GlobalConfiguration().getValue<int>("connectTimeoutProd") * 1000;
  int receiveTimeoutProd =
      GlobalConfiguration().getValue<int>("receiveTimeoutProd") * 1000;
  int connectTimeoutTest =
      GlobalConfiguration().getValue<int>("connectTimeoutTest") * 1000;
  int receiveTimeoutTest =
      GlobalConfiguration().getValue<int>("receiveTimeoutTest") * 1000;

  Moqui({required this.client}) {
    if (kReleaseMode) {
      client.options.baseUrl = prodUrl!;
    } else if (kIsWeb || Platform.isIOS || Platform.isLinux) {
      client.options.baseUrl = 'http://localhost:8080/';
    } else if (Platform.isAndroid) {
      client.options.baseUrl = 'http://10.0.2.2:8080/';
    }
    if (kReleaseMode) {
      client.options.connectTimeout = connectTimeoutProd;
      client.options.receiveTimeout = receiveTimeoutProd;
    } else {
      client.options.connectTimeout = connectTimeoutTest;
      client.options.receiveTimeout = receiveTimeoutTest;
    }

    client.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      if (restRequestLogs) {
        print(
            '===Outgoing dio request path: ${options.baseUrl}${options.path}');
        print('===Outgoing dio request headers: ${options.headers}');
        print('===Outgoing dio request data: ${options.data}');
      }
      return handler.next(options); //continue
    }, onResponse: (response, handler) async {
      if (restResponseLogs) {
        print("===incoming response: ${response.toString()}");
      }
      return handler.next(response); // continue
    }, onError: (DioError e, handler) async {
      // Do something with response error
      if (e.response != null) {
        print("=== e.response.data: ${e.response!.data}");
        print("=== e.response.headers: ${e.response!.headers}");
        print("=== e.response.request: ${e.response!.requestOptions}");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        print("=== e.request: ${e.requestOptions}");
        print("=== e.message: ${e.message}");
      }
      return handler.next(e); //continue
    }));
  }

  String? responseMessage(e) {
    String? errorDescription;
    if (e.response != null) {
      return e.response.data["errors"];
    }

    errorDescription = e.toString();

    if (e is DioErrorType) {
      switch (e) {
        case DioErrorType.cancel:
          errorDescription = 'Request to API server was cancelled';
          break;
        case DioErrorType.connectTimeout:
          errorDescription = 'Connection timeout with API server';
          break;
        case DioErrorType.receiveTimeout:
          errorDescription = 'Receive timeout in connection with API server';
          break;
        case DioErrorType.response:
          errorDescription = 'Internet or server problem?';
          break;
        case DioErrorType.sendTimeout:
          errorDescription = 'Send timeout in connection with API server';
          break;
        case DioErrorType.other:
          errorDescription = 'Default error type, Some other Error.';
          break;
      }
    }

    print('==moqui.dart: returning error message: $errorDescription');
    return errorDescription;
  }

// -----------------------------general ------------------------
  Future<dynamic> getConnected() async {
    try {
      Response response = await client.get('growerp/moquiSessionToken');
      this.sessionToken = response.toString();
      return sessionToken != null; // return true if session token ok
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  void setApikey(String apiKey) {
    client.options.headers['api_key'] = apiKey;
  }

  Future<bool> checkApikey() async {
    try {
      Response response = await client.get('rest/s1/growerp/100/CheckApiKey');
      return response.data["ok"] == "ok"; // return true if session token ok
    } on DioError catch (_) {
      return Future.value(false);
    }
  }

  Future<bool> checkCompany(String partyId) async {
    try {
      Response response = await client.get('rest/s1/growerp/100/CheckCompany',
          queryParameters: {'partyId': partyId});
      return response.data["ok"] == 'ok'; // return true if session token ok
    } on DioError catch (_) {
      return Future.value(false);
    }
  }

  Future<dynamic> getCompanies(
      {String? classificationId,
      int? start,
      int? limit,
      String? filter}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/Companies', queryParameters: {
        "classificationId": classificationId,
        'start': start,
        'limit': limit,
        'filter': filter,
      });
      return companiesFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getItemTypes({bool sales = true}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/ItemTypes', queryParameters: {
        "sales": sales,
      });
      return itemTypesFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  /// The demo store can only register as a customer.
  /// Any other store it depends on the person logging in.
  Future<dynamic> register({
    required String companyName,
    required String firstName,
    required String lastName,
    required String currencyId,
    required String email,
    bool demoData = true,
  }) async {
    try {
      var locale;
      // if (!kIsWeb) locale = await Devicelocale.currentLocale;
      Response response = await client.post(
        'rest/s1/growerp/100/UserAndCompany',
        data: {
          'username': email,
          'emailAddress': email,
          'newPassword': kReleaseMode ? null : 'qqqqqq9!',
          'firstName': firstName,
          'lastName': lastName,
          'companyName': companyName,
          'locale': locale,
          'currencyId': currencyId,
          'companyEmailAddress': email,
          'classificationId': classificationId,
          'productionEnvironment': kReleaseMode.toString(),
          'moquiSessionToken': sessionToken,
          'demoData': demoData.toString()
        },
      );
      return authenticateFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> login(
      {required String username, required String password}) async {
    try {
      Response response = await client.post('rest/s1/growerp/100/Login', data: {
        'username': username,
        'password': password,
        'classificationId': classificationId,
        'moquiSessionToken': this.sessionToken
      });
      dynamic result = jsonDecode(response.toString());
      if (result['passwordChange'] == 'true') return 'passwordChange';
      this.sessionToken = result['moquiSessionToken'];
      client.options.headers['api_key'] = result["apiKey"];
      persistAuthenticate(authenticateFromJson(response.toString()));
      return authenticateFromJson(response.toString());
    } on DioError catch (e) {
      return (responseMessage(e));
    }
  }

  Future<dynamic> resetPassword({required String username}) async {
    try {
      Response result = await client.post('rest/s1/growerp/100/ResetPassword',
          data: {'username': username, 'moquiSessionToken': this.sessionToken});
      return json.decode(result.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updatePassword(
      {required String username,
      required String oldPassword,
      required String newPassword}) async {
    try {
      await client.put('rest/s1/growerp/100/Password', data: {
        'username': username,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'moquiSessionToken': this.sessionToken
      });
      return getAuthenticate();
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> logout(authenticate) async {
    try {
      await client.post('growerp/logout');
      authenticate = authenticate.copyWith(clearApiKey: true);
      await persistAuthenticate(authenticate);
      return authenticate;
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<void> removeAuthenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authenticate');
  }

  Future<void> persistAuthenticate(Authenticate authenticate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('authenticate', authenticateToJson(authenticate));
    if (authenticate.apiKey == null)
      client.options.headers.remove('api_key');
    else
      client.options.headers['api_key'] = authenticate.apiKey;
  }

  Future<Authenticate?> getAuthenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? result = prefs.getString('authenticate');
    // ignore informaton with a bad format
    try {
      if (result != null) return authenticateFromJson(result);
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> getUser(
      {int? start,
      int? limit,
      String? userGroupId,
      String? userPartyId,
      String? filter,
      String? search}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/User', queryParameters: {
        'userPartyId': userPartyId,
        'userGroupId': userGroupId,
        'filter': filter,
        'start': start,
        'limit': limit,
        'search': search
      });
      if (userPartyId == null)
        return usersFromJson(response.toString());
      else {
        return userFromJson(response.toString());
      }
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> registerUser(User user, String ownerPartyId) async {
    try {
      Response response =
          await client.put('rest/s1/growerp/100/RegisterUser', data: {
        'user': userToJson(user),
        'moquiSessionToken': sessionToken,
        'classificationId': classificationId,
        'ownerPartyId': ownerPartyId
      });
      return userFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateUser(User user) async {
    // no partyId is add
    try {
      Response response;
      if (user.partyId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/User', data: {
          'user': userToJson(user),
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/User', data: {
          'user': userToJson(user),
          'moquiSessionToken': sessionToken
        });
      }
      return userFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteUser(String partyId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/User',
          queryParameters: {'partyId': partyId});
      return response.data["partyId"];
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateCompany(Company company) async {
    try {
      Response response = await client.post('rest/s1/growerp/100/Company',
          data: {
            'company': companyToJson(company),
            'moquiSessionToken': sessionToken
          });
      return companyFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getCart(
      {required bool sales, required String docType}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? result = prefs.getString('finDoc$sales$docType');
    // ignore informaton with a bad format
    try {
      if (result != null) return finDocFromJson(result);
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> saveCart(FinDoc finDoc) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          "finDoc${finDoc.sales}${finDoc.docType}", finDocToJson(finDoc));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateFinDoc(FinDoc finDoc) async {
    finDoc = finDoc.copyWith(classificationId: classificationId);
    try {
      Authenticate? authenticate = await (getAuthenticate());
      client.options.headers['api_key'] = authenticate!.apiKey;
      Response response;
      if (finDoc.idIsNull()) // add
        response = await client.post('rest/s1/growerp/100/FinDoc', data: {
          'finDoc': finDocToJson(finDoc),
          'moquiSessionToken': sessionToken
        });
      else // update
        response = await client.patch('rest/s1/growerp/100/FinDoc', data: {
          'finDoc': finDocToJson(finDoc),
          'moquiSessionToken': sessionToken
        });
      // returns a single record in a list
      return finDocsFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getFinDoc(
      {int? start,
      int? limit,
      bool? open,
      bool? sales,
      String? docType,
      DateTime? startDate,
      String? id,
      String? search,
      String? customerCompanyPartyId}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/FinDoc', queryParameters: {
        'sales': sales,
        'docType': docType,
        'open': open,
        'id': id,
        'startDate': '${startDate?.year.toString()}-'
            '${startDate?.month.toString().padLeft(2, '0')}-'
            '${startDate?.day.toString().padLeft(2, '0')}',
        'start': start,
        'limit': limit,
        'search': search,
        'classificationId': classificationId,
        'customerCompanyPartyId': customerCompanyPartyId,
      });
      return finDocsFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getCategory(
      {int? start,
      int? limit,
      String? companyPartyId,
      String? filter,
      String? search}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/Categories', queryParameters: {
        'start': start,
        'limit': limit,
        'companyPartyId': companyPartyId,
        'filter': filter,
        'search': search,
        'classificationId': classificationId,
      });
      return categoriesFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateCategory(ProductCategory category) async {
    // no categoryId is add
    try {
      Response response;
      if (category.categoryId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/Category', data: {
          'category': categoryToJson(category),
          'classificationId': classificationId,
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/Category', data: {
          'category': categoryToJson(category),
          'classificationId': classificationId,
          'moquiSessionToken': sessionToken
        });
      }
      return categoryFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteCategory(String categoryId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/Category',
          queryParameters: {'categoryId': categoryId});
      return response.data["categoryId"];
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getProduct(
      {int? start,
      int? limit,
      String? companyPartyId,
      String? categoryId,
      String? productId,
      String? productTypeId,
      String? assetClassId,
      String? filter,
      String? search}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/Products', queryParameters: {
        'companyPartyId': companyPartyId,
        'categoryId': categoryId,
        'productId': productId,
        'productTypeId': productTypeId,
        'assetClassId': assetClassId,
        'start': start,
        'limit': limit,
        'filter': filter,
        'search': search
      });
      if (productId != null)
        return productFromJson(response.toString());
      else
        return productsFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateProduct(Product product) async {
    // no productId is add
    try {
      Response response;
      if (product.productId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/Product', data: {
          'product': productToJson(product),
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/Product', data: {
          'product': productToJson(product),
          'moquiSessionToken': sessionToken
        });
      }
      return productFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteProduct(String productId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/Product',
          queryParameters: {'productId': productId});
      return response.data["productId"];
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getAsset(
      {int? start,
      int? limit,
      String? companyPartyId,
      String? assetClassId,
      String? assetId,
      String? productId,
      String? filter,
      String? search}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/Asset', queryParameters: {
        'companyPartyId': companyPartyId,
        'assetId': assetId,
        'assetClassId': assetClassId,
        'productId': productId,
        'start': start,
        'limit': limit,
        'filter': filter,
        'search': search
      });
      if (assetId != null)
        return assetFromJson(response.toString());
      else
        return assetsFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateAsset(Asset asset) async {
    // no assetId is add
    try {
      Response response;
      if (asset.assetId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/Asset', data: {
          'asset': assetToJson(asset),
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/Asset', data: {
          'asset': assetToJson(asset),
          'moquiSessionToken': sessionToken
        });
      }
      return assetFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteAsset(String assetId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/Asset',
          queryParameters: {'assetId': assetId});
      return response.data["assetId"];
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getOpportunity(
      {int? start,
      int? limit,
      String? opportunityId,
      bool? all,
      String? search}) async {
    try {
      Response response =
          await client.get('rest/s1/growerp/100/Opportunity', queryParameters: {
        'opportunityId': opportunityId,
        'start': start,
        'limit': limit,
        'all': all.toString(),
        'search': search
      });
      if (opportunityId == null)
        return opportunitiesFromJson(response.toString());
      else
        return opportunityFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateOpportunity(Opportunity opportunity) async {
    // no Id is add
    try {
      Response response;
      if (opportunity.opportunityId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/Opportunity', data: {
          'opportunity': opportunityToJson(opportunity),
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/Opportunity', data: {
          'opportunity': opportunityToJson(opportunity),
          'moquiSessionToken': sessionToken
        });
      }
      return opportunityFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteOpportunity(String opportunityId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/Opportunity',
          queryParameters: {'opportunityId': opportunityId});
      return response.data["opportunityId"];
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getBalanceSheet() async {
    try {
      Response response = await client.get('rest/s1/growerp/100/BalanceSheet');
      return balanceSheetFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getLedger() async {
    try {
      Response response = await client.get('rest/s1/growerp/100/Ledger');
      return glAccountListFromJson(response.toString());
    } on DioError catch (e) {
      return responseMessage(e);
    }
  }
}
