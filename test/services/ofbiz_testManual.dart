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
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/models/@models.dart';
import '../data.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    HttpClient client = super.createHttpClient(context); //<<--- notice 'super'
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

void main() async {
  HttpOverrides.global = new MyHttpOverrides();
  Dio client;

  Authenticate authenticate;
  String username = randomString4 + emailAddress;
  String password = "qqqqqq9!";

  User createdCustomer;
  Product createdProduct;
  Order createdOrder;

  client = Dio();

  client.options.baseUrl = 'https://localhost:8443/rest/';
  client.options.connectTimeout = 20000;
  client.options.receiveTimeout = 40000;
  client.options.headers = {'Content-Type': 'application/json'};
  print(
      "need a local trunk version of OFBiz framework with REST and Growerp plugin");
  print("====================================================================");

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
      // Something happened in setting up or sending the request
      // that triggered an Error
      print("=== e.request: ${e.request}");
      print("=== e.message: ${e.message}");
    }
    return e; //continue
  }));

  String getResponseData(Response input) {
    Map jsonData = json.decode(input.toString()) as Map;
    return json.encode(jsonData["data"]);
  }

  setUpAll(() async {
    // register new company, user and login
    try {
      Response response =
          await client.post('services/registerUserAndCompany100',
              data: jsonEncode({
                "companyName": companyName,
                "currencyId": currencyId,
                "firstName": firstName,
                "lastName": lastName,
                "classificationId": classificationId,
                "emailAddress": emailAddress,
                "companyEmail": emailAddress,
                "username": username,
                "userGroupId": 'GROWERP_M_ADMIN',
                "password": password,
              }));
      authenticate = authenticateFromJson(getResponseData(response));
    } catch (e) {
      print("==catch e======${e.response}");
    }
  });

  group('Public tests>>>>', () {
    test('Ping the system', () async {
      try {
        String msg = "ok?";
        Response response = await client.get('services/growerpPing?inParams=' +
            Uri.encodeComponent('{"message": "$msg" }'));
        Map jsonData = json.decode(response.toString()) as Map;
        String result = jsonData["data"]["message"];
        expect(result, msg);
      } catch (e) {
        print("catch ${e?.response?.data}");
      }
    });
    test('get companies no auth', () async {
      try {
        Response response = await client.get(
            'services/getCompanies100?inParams=' +
                Uri.encodeComponent(
                    '{"classificationId": "$classificationId" }'));
        dynamic result = companiesFromJson(getResponseData(response));
        expect(result != null ? result.length : 0, greaterThan(0));
      } catch (e) {
        print("catch ${e?.response?.data}");
      }
    });

    test('login', () async {
      // get token
      String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$username:$password'));
      client.options.headers["Authorization"] = basicAuth;
      Response response = await client.post('auth/token');
      Map jsonData = json.decode(response.toString()) as Map;
      String token = jsonData["data"]["access_token"];

      client.options.headers["Authorization"] = 'Bearer ' + token;

      expect(jsonData["statusCode"], 200);

      // get company and user data using token
      response = await client.get('services/getAuthenticate100');
      authenticate = authenticateFromJson(getResponseData(response));
      authenticateNoKey.company.partyId = authenticate.company?.partyId;
      authenticateNoKey.user.partyId = authenticate.user?.partyId;
      authenticateNoKey.company.image = null;
      authenticateNoKey.company.employees = authenticate.company?.employees;
      authenticateNoKey.user.name = username;
      authenticateNoKey.user.image = null;
      authenticateNoKey.user.email = emailAddress;
      authenticateNoKey.company.email = emailAddress;
      authenticateNoKey.user.groupDescription =
          authenticate.user.groupDescription;
      expect(authenticateToJson(authenticate),
          authenticateToJson(authenticateNoKey));
    });

    test('check if api_key works', () async {
      try {
        Response response = await client.get('services/checkToken100');
        Map jsonData = json.decode(response.toString()) as Map;
        String ok = jsonData["data"]["ok"];
        expect(ok, 'ok');
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });

  group('Company operations >>>>> ', () {
    test('confirm existing data', () async {
      try {
        authenticate.company.image = null; // fill when want to change
        Response response = await client.post('services/updateCompany100',
            data: companyToJson(authenticate.company));
        dynamic result = companyFromJson(getResponseData(response));
        expect(companyToJson(result), companyToJson(authenticate.company));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('change data of company', () async {
      try {
        authenticate.company.image = null; // fill when want to change
        authenticate.company.name = 'xxxx';
        authenticate.company.email = 'yyyy@yy.co';
        Response response = await client.post('services/updateCompany100',
            data: companyToJson(authenticate.company));
        dynamic result = companyFromJson(getResponseData(response));
        expect(companyToJson(result), companyToJson(authenticate.company));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('upload company image', () async {
      try {
        authenticate.company.image = base64.decode(imageBase64);
        Response response = await client.post('services/updateCompany100',
            data: companyToJson(authenticate.company));
        Company result = companyFromJson(getResponseData(response));
        //  print("====result of company update: ${result.toString()}");
        expect(result?.image, isNotEmpty);
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });

    test('check if a company still exits', () async {
      try {
        Response response = await client.get(
            'services/checkCompany100?inParams=' +
                Uri.encodeComponent(
                    '{"companyPartyId": "${authenticate.company.partyId}" }'));
        Map jsonData = json.decode(response.toString()) as Map;
        String ok = jsonData["data"]["ok"];
        expect(ok, 'ok');
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });

  group('User operations >>>>> ', () {
    test('update logged in user', () async {
      try {
        authenticate.user.image = null; // fill when want to change
        Response response = await client.post('services/updateUser100',
            data: userToJson(authenticate.user));
        dynamic result = userFromJson(getResponseData(response));
        expect(userToJson(result), userToJson(authenticate.user));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('change data of logged in user', () async {
      try {
        authenticate.user.image = null; // fill when want to change
        authenticate.user.firstName = 'xxxx';
        authenticate.user.lastName = 'yyyy';
        Response response = await client.post('services/updateUser100',
            data: userToJson(authenticate.user));
        dynamic result = userFromJson(getResponseData(response));
        expect(userToJson(result), userToJson(authenticate.user));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });

    test('upload user image', () async {
      try {
        authenticate.user.image = base64.decode(imageBase64);
        Response response = await client.post('services/updateUser100',
            data: userToJson(authenticate.user));
        User result = userFromJson(getResponseData(response));
        // print("====result of user update: ${result.toString()}");
        expect(result?.image, isNotEmpty);
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('forget password', () async {
      try {
        // this will change the password
        await client.post('services/resetPassword100',
            data: {'username': authenticate.user.name});
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('delete user', () async {
      try {
        // check if user exist
        Response response = await client.get('services/getUsers100?inParams=' +
            Uri.encodeComponent(
                '{"userPartyId": "${authenticate.user.partyId}" }'));
        Map jsonData = json.decode(response.toString()) as Map;
        expect(false, jsonData["data"]["user"] == null);
        // delete the user
        response = await client.post('services/deleteUser100',
            data: {'userPartyId': authenticate.user.partyId});
        jsonData = json.decode(response.toString()) as Map;
        String userPartyId = jsonData["data"]["userPartyId"];
        expect(userPartyId, authenticate.user.partyId);
        // check agian
        response = await client.get('services/getUsers100?inParams=' +
            Uri.encodeComponent(
                '{"userPartyId": "${authenticate.user.partyId}" }'));
        jsonData = json.decode(response.toString()) as Map;
        expect(true, jsonData["data"]["user"] == null);
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('create customer', () async {
      try {
        customer.email = randomString4 + customer.email;
        customer.name = randomString4 + customer.name;
        Response response = await client.post('services/createUser100',
            data: userToJson(customer));
        User result = userFromJson(getResponseData(response));
        // print("====result of user update: ${result.toString()}");
        createdCustomer = result;
        customer.partyId = result.partyId;
        expect(userToJson(customer), userToJson(result));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });

  group('Category operations >>>>> ', () {
    test('create  category', () async {
      try {
        category.image = null; // fill when want to change
        category.categoryId = null;
        Response response = await client.post('services/createCategory100',
            data: categoryToJson(category));
        dynamic result = categoryFromJson(getResponseData(response));
        category.categoryId = result.categoryId;
        category.image = result.image;
        expect(categoryToJson(result), categoryToJson(category));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('update  category', () async {
      try {
        category.image = null; // fill when want to change
        Response response = await client.post('services/updateCategory100',
            data: categoryToJson(category));
        dynamic result = categoryFromJson(getResponseData(response));
        category.image = result.image;
        expect(categoryToJson(result), categoryToJson(category));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('change data category', () async {
      try {
        category.image = null; // fill when want to change
        category.categoryName = 'xxxx';
        Response response = await client.post('services/updateCategory100',
            data: categoryToJson(category));
        dynamic result = categoryFromJson(getResponseData(response));
        category.image = result.image;
        expect(categoryToJson(result), categoryToJson(category));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });

    test('upload category image', () async {
      try {
        category.image = base64.decode(imageBase64);
        Response response = await client.post('services/updateCategory100',
            data: categoryToJson(category));
        ProductCategory result = categoryFromJson(getResponseData(response));
        // print("====result of category update: ${result.toString()}");
        expect(result?.image, isNotEmpty);
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });

  group('Product operations >>>>> ', () {
    test('create  product', () async {
      try {
        // create category for product
        category.image = null; // fill when want to change
        category.categoryId = null;
        Response response = await client.post('services/createCategory100',
            data: categoryToJson(category));
        dynamic result = categoryFromJson(getResponseData(response));
        product.image = null; // fill when want to change
        product.productId = null;
        product.categoryId = result.categoryId;
        // create the product
        response = await client.post('services/createProduct100',
            data: productToJson(product));
        result = productFromJson(getResponseData(response));
        product.productId = result.productId;
        product.image = result.image;
        createdProduct = product;
        expect(productToJson(result), productToJson(product));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('update  product', () async {
      try {
        product.image = null; // fill when want to change
        Response response = await client.post('services/updateProduct100',
            data: productToJson(product));
        dynamic result = productFromJson(getResponseData(response));
        product.image = result.image;
        expect(productToJson(result), productToJson(product));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('change data product', () async {
      try {
        product.image = null; // fill when want to change
        product.productName = 'xxxx';
        Response response = await client.post('services/updateProduct100',
            data: productToJson(product));
        dynamic result = productFromJson(getResponseData(response));
        product.image = result.image;
        expect(productToJson(result), productToJson(product));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });

    test('upload product image', () async {
      try {
        product.image = base64.decode(imageBase64);
        Response response = await client.post('services/updateProduct100',
            data: productToJson(product));
        Product result = productFromJson(getResponseData(response));
        // print("====result of product update: ${result.toString()}");
        expect(result?.image, isNotEmpty);
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });
  group('Order operations >>>>> ', () {
    test('create/get  order', () async {
      try {
        order.customerPartyId = createdCustomer.partyId;
        order.orderItems[0].productId = createdProduct.productId;
        order.orderItems[0].description = createdProduct.productName;
        order.orderItems[1].productId = createdProduct.productId;
        order.orderItems[1].description = createdProduct.productName;
        Response response = await client.post('services/createOrder100',
            data: orderToJson(order));
        createdOrder = orderFromJson(getResponseData(response));
        order.orderId = createdOrder.orderId;
        order.placedDate = createdOrder.placedDate;
        order.placedTime = createdOrder.placedTime;
        order.firstName = createdCustomer.firstName;
        order.lastName = createdCustomer.lastName;
        order.email = createdCustomer.email;
        order.grandTotal = createdOrder.grandTotal;
        order.orderItems[0].orderItemSeqId =
            createdOrder.orderItems[0].orderItemSeqId;
        order.orderItems[1].orderItemSeqId =
            createdOrder.orderItems[1].orderItemSeqId;
        expect(orderToJson(order), orderToJson(createdOrder));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('get orderList', () async {
      try {
        Response response =
            await client.get('services/getOrders100?inParams={}');
        //print("====$response====");
        List<Order> orders = ordersFromJson(getResponseData(response));
        //print("===orders# ${orders.length}");
        expect(orders.length, 1);
        expect(orderToJson(createdOrder), orderToJson(orders[0]));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });
}
