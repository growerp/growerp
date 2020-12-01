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
import 'dart:io' show File, Platform;
import 'dart:async';
import '../models/@models.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Moqui {
  final Dio client;
  String sessionToken;
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

  Moqui({@required this.client}) {
    if (kReleaseMode) {
      client.options.baseUrl = prodUrl;
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

    client.options.headers = {'Content-Type': 'application/json'};

    client.interceptors
        .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
      if (restRequestLogs) {
        print('===Outgoing dio request path: ${options.path}');
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
      // print("====dio error: $errorDescription");
    }
    if (e?.response != null && e?.response?.data != null) {
      errorDescription = e.response.data["errors"];
    }
    print('==moqui.dart: returning error message: $errorDescription');
    return errorDescription;
  }

// -----------------------------general ------------------------
  Future<dynamic> getConnected() async {
    try {
      Response response = await client.get('rest/moquiSessionToken');
      this.sessionToken = response.toString();
      return sessionToken != null; // return true if session token ok
    } catch (e) {
      return responseMessage(e);
    }
  }

  void setApikey(String apiKey) {
    client.options.headers['api_key'] = apiKey;
  }

  Future<dynamic> checkApikey() async {
    try {
      Response response = await client.get('rest/s1/growerp/100/CheckApiKey');
      return response.data["ok"] == "ok"; // return true if session token ok
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> checkCompany(String partyId) async {
    try {
      Response response = await client.get('rest/s1/growerp/100/CheckCompany',
          queryParameters: {'partyId': partyId});
      return response.data["ok"] == 'ok'; // return true if session token ok
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getCompanies() async {
    try {
      Response response = await client.get('rest/s1/growerp/100/Companies',
          queryParameters: {"classificationId": classificationId});
      return companiesFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  /// The demo store can only register as a customer.
  /// Any other store it depends on the person logging in.
  Future<dynamic> register(
      {String companyName,
      String companyPartyId, // if empty will create new company too!
      @required String firstName,
      @required String lastName,
      String currencyId,
      String classificationId,
      @required String email,
      List data}) async {
    try {
      var locale;
      // if (!kIsWeb) locale = await Devicelocale.currentLocale;
      Response response =
          await client.post('rest/s1/growerp/100/UserAndCompany',
              data: {
                'username': email, 'emailAddress': email,
                'newPassword': 'qqqqqq9!', 'firstName': firstName,
                'lastName': lastName, 'locale': locale,
                'companyPartyId': companyPartyId, // for existing companies
                'companyName': companyName, 'currencyId': currencyId,
                'companyEmailAddress': email,
                'classificationId': classificationId,
                'environment': kReleaseMode,
                'moquiSessionToken': sessionToken
              },
              options: Options(headers: {'api_key': null}));
      return authenticateFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> login(
      {@required String username, @required String password}) async {
    try {
      Response response = await client.post('rest/s1/growerp/100/Login', data: {
        'username': username,
        'password': password,
        'moquiSessionToken': this.sessionToken
      });
      dynamic result = jsonDecode(response.toString());
      if (result['passwordChange'] == 'true') return 'passwordChange';
      this.sessionToken = result['moquiSessionToken'];
      client.options.headers['api_key'] = result["apiKey"];
      return authenticateFromJson(response.toString());
    } catch (e) {
      return (responseMessage(e));
    }
  }

  Future<dynamic> resetPassword({@required String username}) async {
    try {
      Response result = await client.post('rest/s1/growerp/100/ResetPassword',
          data: {'username': username, 'moquiSessionToken': this.sessionToken});
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
      await client.put('rest/s1/growerp/100/Password', data: {
        'username': username,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'moquiSessionToken': this.sessionToken
      });
      return getAuthenticate();
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> logout() async {
    try {
      await client.post('rest/logout');
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
    } else {
      await prefs.setString('authenticate', null);
    }
    client.options.headers['api_key'] = authenticate?.apiKey;
  }

  Future<Authenticate> getAuthenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString('authenticate');
    if (result != null) return authenticateFromJson(result);
    return null;
  }

  Future<dynamic> getUser({String userPartyId, String userGroupId}) async {
    try {
      Response response = await client.get('rest/s1/growerp/100/User',
          queryParameters: {
            'userPartyId': userPartyId,
            'userGroupId': userGroupId
          });
      if (userPartyId == null)
        return usersFromJson(response.toString());
      else {
        return userFromJson(response.toString());
      }
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateUser(User user, [String imagePath]) async {
    // no partyId is add
    try {
      user.image = null;
      String base64Image;
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          base64Image = base64Encode(response.bodyBytes);
        } else {
          base64Image = base64Encode(File(imagePath).readAsBytesSync());
        }
      }
      Response response;
      if (user.partyId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/User', data: {
          'user': userToJson(user),
          'base64': base64Image,
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/User', data: {
          'user': userToJson(user),
          'base64': base64Image,
          'moquiSessionToken': sessionToken
        });
      }
      return userFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteUser(String partyId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/User',
          queryParameters: {'partyId': partyId});
      return response.data["partyId"];
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateCompany(Company company, String imagePath) async {
    try {
      company.image = null;
      String base64Image;
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          base64Image = base64Encode(response.bodyBytes);
        } else {
          base64Image = base64Encode(File(imagePath).readAsBytesSync());
        }
      }
      Response response =
          await client.post('rest/s1/growerp/100/Company', data: {
        'company': companyToJson(company),
        'base64': base64Image,
        'moquiSessionToken': sessionToken
      });
      return companyFromJson(response.toString());
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
      Response response = await client.get(
          'rest/s1/growerp/100/CategoriesAndProducts',
          queryParameters: {'companyPartyId': companyPartyId});
      return catalogFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getCart() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
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

  Future<dynamic> createOrder(Order order) async {
    try {
      Authenticate authenticate = await getAuthenticate();
      client.options.headers['api_key'] = authenticate.apiKey;
      Response response = await client.post('rest/s1/growerp/100/Order', data: {
        'order': orderToJson(order),
        'moquiSessionToken': sessionToken
      });
      return orderFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getOrders() async {
    try {
      Response response = await client.get('rest/s1/growerp/100/Order');
      return ordersFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> getOrder(String orderId) async {
    try {
      Response response = await client.get('rest/s1/growerp/100/Order',
          queryParameters: {'orderId': orderId});
      print("=====receiving single order: $response");
      return orderFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateCategory(
      ProductCategory category, String imagePath) async {
    // no categoryId is add
    try {
      category.image = null;
      String base64Image;
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          base64Image = base64Encode(response.bodyBytes);
        } else {
          base64Image = base64Encode(File(imagePath).readAsBytesSync());
        }
      }
      Response response;
      if (category.categoryId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/Category', data: {
          'category': categoryToJson(category),
          'base64': base64Image,
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/Category', data: {
          'category': categoryToJson(category),
          'base64': base64Image,
          'moquiSessionToken': sessionToken
        });
      }
      return categoryFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteCategory(String categoryId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/Category',
          queryParameters: {'categoryId': categoryId});
      return response.data["categoryId"];
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> updateProduct(Product product, String imagePath) async {
    // no productId is add
    try {
      product.image = null;
      String base64Image;
      if (imagePath != null) {
        if (kIsWeb) {
          var response = await get(imagePath);
          base64Image = base64Encode(response.bodyBytes);
        } else {
          base64Image = base64Encode(File(imagePath).readAsBytesSync());
        }
      }
      Response response;
      if (product.productId != null) {
        //update
        response = await client.patch('rest/s1/growerp/100/Product', data: {
          'product': productToJson(product),
          'base64': base64Image,
          'moquiSessionToken': sessionToken
        });
      } else {
        //create
        response = await client.put('rest/s1/growerp/100/Product', data: {
          'product': productToJson(product),
          'base64': base64Image,
          'moquiSessionToken': sessionToken
        });
      }
      return productFromJson(response.toString());
    } catch (e) {
      return responseMessage(e);
    }
  }

  Future<dynamic> deleteProduct(String productId) async {
    try {
      Response response = await client.delete('rest/s1/growerp/100/Product',
          queryParameters: {'productId': productId});
      return response.data["productId"];
    } catch (e) {
      return responseMessage(e);
    }
  }
}
