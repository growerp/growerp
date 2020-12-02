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
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';
import 'data.dart';

void main() {
  Dio client;
  String sessionToken;
  String apiKey;
  Map login = Map<dynamic, dynamic>();
  Authenticate authenticate;
  Authenticate loginAuth;
  String categoryId;
  String productId;

  client = Dio();
  client.options.baseUrl = 'http://localhost:8080/rest/';
  client.options.connectTimeout = 20000; //10s
  client.options.receiveTimeout = 40000;
  client.options.headers = {'Content-Type': 'application/json'};
  client.interceptors
      .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
    if (false) {
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
    if (false) {
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

  setUp(() async {
    Response response = await client.get('moquiSessionToken');
    sessionToken = response.data;
  });

  group('Connection test and public api >>>>>', () {
    test('test connection', () async {
      print("need a local version of Moqui see: README of this project");
      print("=========================================================");
      Response response = await client.get('moquiSessionToken');
      sessionToken = response.data;
      expect(response.data.length, 20);
    });
  });

  group('Register first company, login>>>>>', () {
    test('register', () async {
      register['moquiSessionToken'] = sessionToken;
      register['username'] = randomString4 + register['emailAddress'];
      register['emailAddress'] = randomString4 + register['emailAddress'];
      register['classificationId'] = 'AppAdmin';
      dynamic response =
          await client.post('s1/growerp/100/UserAndCompany', data: register);
      Authenticate result = authenticateFromJson(response.toString());
      authenticateNoKey.company.partyId = result.company.partyId;
      authenticateNoKey.user.partyId = result.user.partyId;
      authenticateNoKey.user.name = register['emailAddress'];
      authenticateNoKey.user.email = register['emailAddress'];
      authenticateNoKey.user.image = result.user.image;
      authenticateNoKey.user.userId = result.user.userId;
      authenticateNoKey.user.language = result.user.language;
      authenticateNoKey.company.image = result.company.image;
      authenticateNoKey.company.employees = result.company.employees;
      authenticateNoKey.company.classificationId =
          result.company.classificationId;
      authenticateNoKey.company.classificationDescr =
          result.company.classificationDescr;
      authenticateNoKey.apiKey = result.apiKey;
      apiKey = result.apiKey;
      // used later for login test
      login.addAll({
        'companyPartyId': result.company.partyId,
        'username': result.user?.name,
        'password': password
      });
      authenticate = authenticateNoKey;
      expect(authenticateToJson(result), authenticateToJson(authenticateNoKey));
    });

    test('Companies', () async {
      Response response = await client.get('s1/growerp/100/Companies');
      dynamic result = companiesFromJson(response.toString());
      expect(result.length > 0, true);
    });

    test('login', () async {
      dynamic response = await client.post('s1/growerp/100/Login', data: login);
      loginAuth = authenticateFromJson(response.toString());
      authenticate.apiKey = loginAuth.apiKey;
      apiKey = loginAuth.apiKey;
      client.options.headers['api_key'] = loginAuth.apiKey;
      authenticate.moquiSessionToken = loginAuth.moquiSessionToken;
      sessionToken = loginAuth.moquiSessionToken;
      expect(authenticateToJson(loginAuth), authenticateToJson(authenticate));
    });
  });

  group('Catalog >>>>>', () {
    test('create/get category ', () async {
      client.options.headers['api_key'] = apiKey;
      try {
        category.categoryId = null;
        Response response = await client.put('s1/growerp/100/Category', data: {
          'category': categoryToJson(category),
          'moquiSessionToken': sessionToken
        });
        categoryId = categoryFromJson(response.toString()).categoryId;
        expect(categoryToJson(category),
            categoryToJson(categoryFromJson(response.toString())));
      } catch (e) {}
    });
    test('create/get product ', () async {
      client.options.headers['api_key'] = apiKey;
      try {
        product.productId = null;
        product.categoryId = categoryId;
        Response response = await client.put('s1/growerp/100/Product', data: {
          'product': productToJson(product),
          'moquiSessionToken': sessionToken
        });
        productId = productFromJson(response.toString()).productId;
        expect(productToJson(product),
            productToJson(productFromJson(response.toString())));
      } catch (e) {}
    });
  });

  group('Image upload tests>>>>>', () {
    test('upload image company', () async {
      await client.post('s1/growerp/100/Image', data: {
        'type': 'company',
        'id': loginAuth.company.partyId,
        'base64': imageBase64,
        'moquiSessionToken': sessionToken,
      });
      dynamic response = await client.get('s1/growerp/100/Company',
          queryParameters: {'partyId': loginAuth.company.partyId});
      Company company = companyFromJson(response.toString());
      expect(company.image, isNotEmpty);
    });
    test('upload image user', () async {
      await client.post('s1/growerp/100/Image', data: {
        'type': 'user',
        'id': loginAuth.user.partyId,
        'base64': imageBase64,
        'moquiSessionToken': sessionToken,
      });
      dynamic response = await client.get('s1/growerp/100/User',
          queryParameters: {'userPartyId': loginAuth.user.partyId});
      User user = userFromJson(response.toString());
      expect(user.image, isNotEmpty);
    });

    test('upload image category', () async {
      await client.post('s1/growerp/100/Image', data: {
        'type': 'category',
        'id': categoryId,
        'base64': imageBase64,
        'moquiSessionToken': sessionToken,
      });

      dynamic response = await client.get('s1/growerp/100/Categories',
          queryParameters: {'categoryId': categoryId});
      ProductCategory category = categoryFromJson(response.toString());
      expect(category.image, isNotEmpty);
    });

    test('upload image product', () async {
      await client.post('s1/growerp/100/Image', data: {
        'type': 'product',
        'id': productId,
        'base64': imageBase64,
        'moquiSessionToken': sessionToken,
      });

      dynamic response = await client.get('s1/growerp/100/Products',
          queryParameters: {'productId': productId});
      Product product = productFromJson(response.toString());
      expect(product.image, isNotEmpty);
    });
  });

  group('password reset and update >>>>>', () {
    test('update password', () async {
      Map updPassword = {
        'username': login['username'],
        'oldPassword': password,
        'newPassword': newPassword,
        'moquiSessionToken': sessionToken,
      };
      dynamic response =
          await client.put('s1/growerp/100/Password', data: updPassword);
      expect(response.data['messages'].substring(0, 16), 'Password updated');
    });
    test('reset password', () async {
      Response response = await client.post('s1/growerp/100/ResetPassword',
          data: {
            'username': login['username'],
            'moquiSessionToken': sessionToken
          });
      expect(response.data['messages'].substring(0, 25),
          'A reset password was sent');
    });
  });

  group('Order >>>>>', () {
    test('create/get order ', () async {
      client.options.headers['api_key'] = apiKey;
      try {
        // create customer
        customer.name = randomString4;
        customer.email = "$randomString4@example.com";
        Response response = await client.put('s1/growerp/100/User', data: {
          'user': userToJson(customer),
          'moquiSessionToken': sessionToken
        });
        User newCustomer = userFromJson(response.toString());
        order.customerPartyId = newCustomer.partyId;
        order.orderId = null;
        order.orderItems[0].productId = productId;
        order.orderItems[1].productId = productId;
        // create/get order;
        response = await client.post('s1/growerp/100/Order', data: {
          'order': orderToJson(order),
          'moquiSessionToken': sessionToken
        });
        expect(orderToJson(order),
            orderToJson(orderFromJson(response.toString())));
      } catch (e) {}
    });
  });
}
