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
import 'package:http/http.dart' show get;
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../models/@models.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Ofbiz {
  final Dio client;

  String classificationId = GlobalConfiguration().get("classificationId");
  String prodUrl = GlobalConfiguration().get("prodUrl");
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

  Ofbiz({@required this.client}) {
    if (kReleaseMode) {
      client.options.baseUrl = prodUrl;
    } else if (kIsWeb) {
      // when flutter web need apache httpd webserver in front
      client.options.baseUrl = 'http://localhost/rest/';
    } else if (Platform.isIOS || Platform.isLinux) {
      client.options.baseUrl = 'http://localhost:8080/rest/';
    } else if (Platform.isAndroid) {
      client.options.baseUrl = 'http://10.0.2.2:8080/rest/';
    }
    if (kReleaseMode) {
      client.options.connectTimeout = connectTimeoutProd;
      client.options.receiveTimeout = receiveTimeoutProd;
    } else {
      client.options.connectTimeout = connectTimeoutTest;
      client.options.receiveTimeout = receiveTimeoutTest;
    }

    client.options.headers = {'Content-Type': 'application/json'};

    //  processing in/out going backend requests
    client.interceptors
        .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
      if (restRequestLogs) {
        print('===Outgoing dio request ${options.baseUrl}${options.path}');
        print('===Outgoing dio request headers: ${options.headers}');
        print('===Outgoing dio request data: ${options.data}');
      }
      // Do something before request is sent
      return options; //continue
      // If you want to resolve the request with some custom data，
      // you can return a `Response` object or return `dio.resolve(data)`.
      // If you want to reject the request with a error message,
      // you can return a `DioError` object or return `dio.reject(errMsg)`
    }, onResponse: (Response response) async {
      // Do something with response data
      if (restResponseLogs) {
        print("===incoming response: ${response.toString()}");
      }
      return response; // continue
    }, onError: (DioError e) async {
      // Do something with response error
      if (e.response != null) {
        print("=== e.response.data: ${e.response.data}");
        print("=== e.response.headers: ${e.response.headers}");
        print("=== e.response.request: ${e.response.request}");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        print("=== e.request: ${e.request}");
        print("=== e.message: ${e.message}");
      }
      return e; //continue
    }));
  }

  String responseMessage(e) {
    String errorDescription = e.toString();
    if (e is DioError) {
      DioError dioError = e;
      switch (dioError.type) {
        case DioErrorType.CANCEL:
          errorDescription = 'Request to API server was cancelled';
          break;
        case DioErrorType.CONNECT_TIMEOUT:
          errorDescription = 'Connection timeout with API server';
          break;
        case DioErrorType.DEFAULT:
          errorDescription =
              'Connection to API server failed due to internet connection';
          break;
        case DioErrorType.RECEIVE_TIMEOUT:
          errorDescription = 'Receive timeout in connection with API server';
          break;
        case DioErrorType.RESPONSE:
          errorDescription = 'Internet or server problem?';
          break;
        case DioErrorType.SEND_TIMEOUT:
          errorDescription = 'Send timeout in connection with API server';
          break;
      }
      print("===dio error: $errorDescription");
    }
    if (e.response != null && e.response.data != null) {
      print("=====e.response: ${e.response.toString()}");
      print("=====e.response.data: ${e.response.data}");
    }
    print('==ofbiz.dart: returning error message: $errorDescription');
    return errorDescription;
  }

  String getResponseData(Response input, [String field]) {
    Map jsonData = json.decode(input.toString()) as Map;
    if (field != null) return jsonData["data"][field];
    return json.encode(jsonData["data"]);
  }

// -----------------------------general ------------------------
  Future<dynamic> getConnected() async {
    try {
      String msg = "ok?";
      Response response = await client.get('services/growerpPing?inParams=' +
          Uri.encodeComponent('{"message": "$msg" }'));
      return getResponseData(response, "msg") == msg;
    } catch (e) {
      return responseMessage(e);
    }
  }

  void setApikey(String apiKey) {
    if (apiKey != null)
      client.options.headers["Authorization"] = 'Bearer ' + apiKey;
  }

  Future<dynamic> checkApikey() async {
    try {
      Response response = await client.get('services/checkToken100');
      // return true if session token ok
      return getResponseData(response, "ok") == "ok";
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> checkCompany(String partyId) async {
    try {
      Response response = await client.get(
          'services/checkCompany100?inParams=' +
              Uri.encodeComponent('{"companyPartyId": "$partyId"}'));
      // return true if session token ok
      return getResponseData(response, "ok") == "ok";
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getCompanies() async {
    try {
      Response response = await client.get(
          'services/getCompanies100?inParams=' +
              Uri.encodeComponent(
                  '{"classificationId": "$classificationId" }'));
      if (getResponseData(response) == '{}') return List<Company>();
      return companiesFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> register(
      {String companyName,
      String companyPartyId, // if empty will create new company too!
      @required String firstName,
      @required String lastName,
      @required String currencyId,
      @required String classificationId,
      @required String email,
      List data}) async {
    try {
      var locale;
      // if (!kIsWeb) locale = await Devicelocale.currentLocale;
      Response response =
          await client.post('services/registerUserAndCompany100', data: {
        "companyName": companyName,
        "currencyId": currencyId,
        "firstName": firstName,
        "lastName": lastName, 'locale': locale,
        "classificationId": classificationId,
        "emailAddress": email,
        "companyEmail": email,
        "username": email,
        "userGroupId": 'GROWERP_M_ADMIN',
        "password": 'qqqqqq9!', // TODO: should be removed
        "passwordVerify": 'qqqqqq9!' // TODO: should be removed
      });
      return authenticateFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> login(
      {@required String companyPartyId,
      @required String username,
      @required String password}) async {
    try {
      String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$username:$password'));
      client.options.headers["Authorization"] = basicAuth;
      Response response = await client.post('auth/token');
      String token = getResponseData(response, "access_token");
      client.options.headers["Authorization"] = 'Bearer ' + token;

      response = await client.get('services/getAuthenticate100');
      dynamic result = authenticateFromJson(getResponseData(response));
      if (result is Authenticate) result.apiKey = token;
      return result;
    } catch (e) {
      return (responseMessage(e));
    }
  }

  Future<dynamic> resetPassword({@required String username}) async {
    try {
      Response result = await client
          .post('services/resetPassword100', data: {'username': username});
      return json.decode(result.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updatePassword(
      {@required String username,
      @required String oldPassword,
      @required String newPassword}) async {
    try {
      await client.put('services/updatePassword100', data: {
        'username': username,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      return getAuthenticate();
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> logout() async {
    try {
      Authenticate authenticate = await getAuthenticate();
      authenticate.apiKey = null;
      persistAuthenticate(authenticate);
      return authenticate;
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<void> persistAuthenticate(Authenticate authenticate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (authenticate != null) {
      await prefs.setString('authenticate', authenticateToJson(authenticate));
      if (authenticate?.apiKey != null)
        client.options.headers["Authorization"] =
            'Bearer ' + authenticate?.apiKey;
    } else {
      await prefs.setString('authenticate', null);
    }
  }

  Future<Authenticate> getAuthenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString('authenticate');
    if (result != null) return authenticateFromJson(result);
    return null;
  }

  Future<dynamic> getUser({String userPartyId, String userGroupId}) async {
    try {
      Response response = await client.get('services/getUsers100?inParams=' +
          Uri.encodeComponent(
              '{"userPartyId": "$userPartyId", "usergroupId": "$userGroupId" }'));
      if (userPartyId == null) {
        if (getResponseData(response) == "{}") return List<User>();
        return usersFromJson(getResponseData(response));
      } else {
        if (getResponseData(response) == "{}") return User();
        return userFromJson(getResponseData(response));
      }
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateUser(User user, [String imagePath]) async {
    // no partyId is add
    try {
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          user.image = response.bodyBytes;
        } else {
          user.image = File(imagePath).readAsBytesSync();
        }
      }

      Response response;
      if (user.partyId != null) {
        //update
        response =
            await client.post('services/updateUser100', data: userToJson(user));
      } else {
        //create
        response =
            await client.post('services/createUser100', data: userToJson(user));
      }
      return userFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteUser(String partyId) async {
    try {
      Response response = await client
          .post('services/deleteUser100', data: {'userPartyId': partyId});
      return getResponseData(response, "userPartyId");
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateCompany(Company company, String imagePath) async {
    try {
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          company.image = response.bodyBytes;
        } else {
          company.image = File(imagePath).readAsBytesSync();
        }
      } else
        company.image = null;

      Response response = await client.post('services/updateCompany100',
          data: companyToJson(company));
      return companyFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getCatalog(String companyPartyId) async {
    try {
/*      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('categoriesAndProducts', response.toString());
      String catProdJson = prefs.getString('categoriesAndProducts');
      if (catProdJson != null) return catalogFromJson(catProdJson);
*/
      Response response = await client.get('services/getCatalog100?inParams=' +
          Uri.encodeComponent('{"companyPartyId": "$companyPartyId"}'));
      Catalog result = catalogFromJson(getResponseData(response));
      if (result.categories == null) result.categories = [];
      if (result.products == null) result.products = [];
      return result;
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getCart() async {
    try {
//      SharedPreferences prefs = await SharedPreferences.getInstance();
//      String orderJson = prefs.getString('orderAndItems');
//      if (orderJson != null) return orderFromJson(orderJson);
      return null;
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> saveCart({Order order}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'orderAndItems', order == null ? null : orderToJson(order));
      return null;
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateCategory(
      ProductCategory category, String imagePath) async {
    // no categoryId is add
    try {
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          category.image = response.bodyBytes;
        } else {
          category.image = File(imagePath).readAsBytesSync();
        }
      }

      Response response;
      if (category.categoryId != null) {
        //update
        response = await client.post('services/updateCategory100',
            data: categoryToJson(category));
      } else {
        //create
        response = await client.post('services/createCategory100',
            data: categoryToJson(category));
      }
      return categoryFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteCategory(String categoryId) async {
    try {
      Response response = await client
          .post('services/deleteCategory100', data: {'categoryId': categoryId});
      return getResponseData(response, "categoryId");
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateProduct(Product product, String imagePath) async {
    // no productId is add
    print("======create prod $product");
    try {
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          product.image = response.bodyBytes;
        } else {
          product.image = File(imagePath).readAsBytesSync();
        }
      }

      Response response;
      if (product.productId != null) {
        //update
        response = await client.post('services/updateProduct100',
            data: productToJson(product));
      } else {
        //create
        response = await client.post('services/createProduct100',
            data: productToJson(product));
      }
      return productFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteProduct(String productId) async {
    try {
      Response response = await client
          .post('services/deleteProduct100', data: {'productId': '$productId'});
      return getResponseData(response, "productId");
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> createOrder(Order order) async {
    try {
      Response response = await client.post('services/createOrder100',
          data: orderToJson(order));
      return orderFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getOrders() async {
    try {
      Response response = await client.get('services/getOrders100?inParams={}');
      if (getResponseData(response) == '{}') return List<Order>();
      return ordersFromJson(getResponseData(response));
    } catch (e) {
      return responseMessage(e);
    }
  }
}
