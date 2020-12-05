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
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:models/models.dart';
import 'package:moqui/moqui.dart';
import 'package:mockito/mockito.dart';
import 'package:testdata/testdata.dart';

class DioAdapterMock extends Mock implements HttpClientAdapter {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Dio tdio = Dio();
  DioAdapterMock dioAdapterMock;
  Moqui repos;

  setUpAll(() async {
    dioAdapterMock = DioAdapterMock();
    tdio.httpClientAdapter = dioAdapterMock;
    repos = Moqui(client: tdio);
  });

  group('Repos test', () {
    test('Initial connection', () async {
      final responsepayload = jsonEncode({"data": "ytryrruyuuy"});
      final httpResponse = ResponseBody.fromString(
        responsepayload,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      when(dioAdapterMock.fetch(any, any, any))
          .thenAnswer((_) async => httpResponse);

      final response = await repos.getConnected();
      final expected = true;

      expect(response, equals(expected));
    });

    test('Get companies', () async {
      final responsepayload = companiesToJson(companies);
      final httpResponse = ResponseBody.fromString(
        responsepayload,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      when(dioAdapterMock.fetch(any, any, any))
          .thenAnswer((_) async => httpResponse);

      final response = await repos.getCompanies(null);
      final expected = companies;
      expect(companiesToJson(response), equals(companiesToJson(expected)));
    });

    test('Register', () async {
      final responsepayload = jsonEncode(authenticateNoKey);
      final httpResponse =
          ResponseBody.fromString(responsepayload, 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });

      when(dioAdapterMock.fetch(any, any, any))
          .thenAnswer((_) async => httpResponse);

      final response = await repos.register(
          companyName: companyName,
          firstName: firstName,
          lastName: lastName,
          currencyId: currencyId,
          email: emailAddress);
      final expected = authenticateNoKey;

      expect(
          authenticateToJson(response), equals(authenticateToJson(expected)));
    });
    test('Login', () async {
      final responsepayload = jsonEncode(authenticate);
      final httpResponse =
          ResponseBody.fromString(responsepayload, 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });

      when(dioAdapterMock.fetch(any, any, any))
          .thenAnswer((_) async => httpResponse);

      final response =
          await repos.login(username: username, password: password);
      final expected = authenticate;

      expect(
          authenticateToJson(response), equals(authenticateToJson(expected)));
    });
    test('Reset Password', () async {
      final responsepayload =
          jsonEncode({'messages': 'A reset password was sent'});
      final httpResponse =
          ResponseBody.fromString(responsepayload, 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });

      when(dioAdapterMock.fetch(any, any, any))
          .thenAnswer((_) async => httpResponse);

      final response = await repos.resetPassword(username: username);
      final expected = {'messages': 'A reset password was sent'};

      expect(response, equals(expected));
    });
  });
}
