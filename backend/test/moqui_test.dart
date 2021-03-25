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
import 'package:models/@models.dart';
import 'testdata.dart';
import 'package:decimal/decimal.dart';

void main() {
  Dio client;
  String sessionToken;
  String apiKey;
  Map login = Map<dynamic, dynamic>();
  Authenticate authenticate;
  Authenticate loginAuth;
  String categoryId;
  String productId;
  FinDoc order;

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

  setUpAll(() async {
    Response response = await client.get('moquiSessionToken');
    sessionToken = response.data;

    try {
      register['moquiSessionToken'] = sessionToken;
      register['username'] = randomString4 + register['emailAddress'];
      register['emailAddress'] = randomString4 + register['emailAddress'];
      dynamic response =
          await client.post('s1/growerp/100/UserAndCompany', data: register);
      Authenticate result = authenticateFromJson(response.toString());

      apiKey = result.apiKey;
      // used later for login test
      login.addAll({
        'companyPartyId': result.company.partyId,
        'username': result.user?.name,
        'password': password
      });
      expect(true, result is Authenticate);
    } catch (e) {
      print("catch: $e");
      expect(true, false);
    }
  });

  group('Companies & Login >>>>>', () {
    test('Companies', () async {
      try {
        Response response = await client.get('s1/growerp/100/Companies');
        dynamic result = companiesFromJson(response.toString());
        expect(result.length > 0, true);
      } catch (e) {
        print("catch: $e");
        expect(true, false);
      }
    });
    test('login', () async {
      try {
        dynamic response =
            await client.post('s1/growerp/100/Login', data: login);
        loginAuth = authenticateFromJson(response.toString());
        apiKey = loginAuth.apiKey;
        sessionToken = loginAuth.moquiSessionToken;
        expect(true, loginAuth is Authenticate);
      } catch (e) {
        print("===catch: $e");
        expect(true, false);
      }
    });
  });

  group('Catalog >>>>>', () {
    test('create/get category ', () async {
      client.options.headers['api_key'] = apiKey;
      try {
        Response response = await client.put('s1/growerp/100/Category', data: {
          'category': categoryToJson(category),
          'moquiSessionToken': sessionToken
        });
        ProductCategory result = categoryFromJson(response.toString());
        category = category.copyWith(
            categoryId: result.categoryId, image: result.image);
        categoryId = result.categoryId;
        expect(categoryToJson(category), categoryToJson(result));
        expect(true, result.image != null);
      } catch (e) {
        print("catch: $e");
        expect(true, false);
      }
    });
    test('create/get product ', () async {
      client.options.headers['api_key'] = apiKey;
      try {
        product = product.copyWith(productId: null, categoryId: categoryId);
        Response response = await client.put('s1/growerp/100/Product', data: {
          'product': productToJson(product),
          'moquiSessionToken': sessionToken
        });
        Product result = productFromJson(response.toString());
        product = product.copyWith(
            productId: result.productId,
            image: result.image,
            categoryName: result.categoryName);
        expect(productToJson(product), productToJson(result));
        expect(true, result.image != null);
      } catch (e) {
        print("catch: $e");
        expect(true, false);
      }
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

  group('FinDoc >>>>>', () {
    test('create/get order ', () async {
      client.options.headers['api_key'] = apiKey;
      try {
        // create customer
        User customer = User(
            firstName: randomString4,
            lastName: randomString4,
            email: "$randomString4@example.com",
            userGroupId: "GROWERP_M_CUSTOMER",
            companyName: randomString4);
        Response response = await client.put('s1/growerp/100/User', data: {
          'user': userToJson(customer),
          'moquiSessionToken': sessionToken
        });
        customer = userFromJson(response.toString());

        order = FinDoc(
            docType: 'order',
            sales: true,
            description: 'test order',
            otherUser: customer,
            items: [
              FinDocItem(
                  itemSeqId: 1,
                  itemTypeId: 'ItemProduct',
                  productId: productId,
                  quantity: Decimal.parse("3"),
                  price: Decimal.parse("34.88"))
            ]);

        // create/get order;
        response = await client.post('s1/growerp/100/FinDoc', data: {
          'finDoc': finDocToJson(order),
          'moquiSessionToken': sessionToken
        });
        FinDoc resultOrder = finDocFromJson(response.toString());
        expect(true, resultOrder is FinDoc);
        order = order.copyWith(
            orderId: resultOrder.orderId,
            creationDate: resultOrder.creationDate,
            statusId: resultOrder.statusId,
            grandTotal: resultOrder.grandTotal);
        expect(finDocToJson(order), finDocToJson(resultOrder));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('Update order status to OrderPlaced', () async {
      client.options.headers['api_key'] = apiKey;
      order = order.copyWith(statusId: 'FinDocCreated');
      try {
        Response response = await client.patch('s1/growerp/100/FinDoc', data: {
          'finDoc': finDocToJson(order),
          'moquiSessionToken': sessionToken
        });
        FinDoc resultOrder = finDocFromJson(response.toString());
        expect(resultOrder.invoiceId != null, true);
        expect(resultOrder.paymentId != null, true);
        order = order.copyWith(
            statusId: 'FinDocCreated',
            invoiceId: resultOrder.invoiceId,
            paymentId: resultOrder.paymentId);
        expect(finDocToJson(resultOrder), finDocToJson(order));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('Update order status to OrderApproved', () async {
      client.options.headers['api_key'] = apiKey;
      order = order.copyWith(statusId: 'FinDocApproved');
      try {
        Response response = await client.patch('s1/growerp/100/FinDoc', data: {
          'finDoc': finDocToJson(order),
          'moquiSessionToken': sessionToken
        });
        FinDoc resultOrder = finDocFromJson(response.toString());
        order = order.copyWith(
            statusId: 'FinDocApproved',
            invoiceId: resultOrder.invoiceId,
            paymentId: resultOrder.paymentId);
        expect(finDocToJson(resultOrder), finDocToJson(order));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
    test('Update order status to OrderComplated', () async {
      client.options.headers['api_key'] = apiKey;
      order = order.copyWith(statusId: 'FinDocCompleted');
      try {
        Response response = await client.patch('s1/growerp/100/FinDoc', data: {
          'finDoc': finDocToJson(order),
          'moquiSessionToken': sessionToken
        });
        FinDoc resultOrder = finDocFromJson(response.toString());
        order = order.copyWith(
            statusId: 'FinDocCompleted',
            invoiceId: resultOrder.invoiceId,
            paymentId: resultOrder.paymentId);
        expect(finDocToJson(resultOrder), finDocToJson(order));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });

  group('Opportunity >>>>>', () {
    test('create/get opportunity ', () async {
      client.options.headers['api_key'] = apiKey;
      try {
        // create lead
        User lead = User(
            firstName: randomString4,
            lastName: randomString4,
            email: "$randomString4@example1.com",
            userGroupId: "GROWERP_M_LEAD",
            companyName: randomString4);
        Response response = await client.put('s1/growerp/100/User', data: {
          'user': userToJson(lead),
          'moquiSessionToken': sessionToken
        });
        lead = userFromJson(response.toString());
        opportunity = opportunity.copyWith(
            leadPartyId: lead.partyId,
            leadEmail: lead.email,
            leadFirstName: lead.firstName,
            leadLastName: lead.lastName);
        // create/get opportunity;
        response = await client.put('s1/growerp/100/Opportunity', data: {
          'opportunity': opportunityToJson(opportunity),
          'moquiSessionToken': sessionToken
        });
        Opportunity result = opportunityFromJson(response.toString());
        expect(
            opportunityToJson(opportunity.copyWith(
              opportunityId: result.opportunityId,
              lastUpdated: result.lastUpdated,
            )),
            opportunityToJson(result));
      } on DioError catch (e) {
        expect(null, e?.response?.data);
      }
    });
  });
}
