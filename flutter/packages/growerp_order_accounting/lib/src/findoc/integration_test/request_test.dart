/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

import 'integration_test.dart';

class RequestTest {
  static Future<void> selectRequests(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbRequests', 'FinDocListRequest');
  }

  static Future<void> addRequests(
    WidgetTester tester,
    List<FinDoc> requests, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.requests.isEmpty) {
      // not yet created
      await PersistFunctions.persistTest(
        test.copyWith(requests: await enterRequestData(tester, requests)),
      );
    }
    if (check) {
      await checkRequest(tester, test.requests);
    }
  }

  static Future<void> updateRequests(
    WidgetTester tester,
    List<FinDoc> requests,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    var newRequests = List.of(test.requests);
    if (newRequests[0].grandTotal != requests[0].grandTotal) {
      // copy new request data with requestId
      for (int x = 0; x < test.requests.length; x++) {
        newRequests[x] = requests[x].copyWith(
          requestId: test.requests[x].requestId,
          pseudoId: test.requests[x].requestId,
        );
      }
      // update existing records, no need to use return data
      await enterRequestData(tester, newRequests);
      await PersistFunctions.persistTest(test.copyWith(requests: newRequests));
    }
    await checkRequest(tester, newRequests);
  }

  static Future<List<FinDoc>> enterRequestData(
    WidgetTester tester,
    List<FinDoc> requests,
  ) async {
    List<FinDoc> newRequests = [];
    for (FinDoc request in requests) {
      if (request.requestId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: request.requestId!);
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          request.requestId,
          reason: 'found different detail than was searched for',
        );
      }
      await CommonTest.checkWidgetKey(tester, "RequestDialog");
      await CommonTest.enterDropDownSearch(
        tester,
        'otherCompanyUser',
        toCompanyUser(request.otherCompany ?? request.otherUser)!.name!,
        seconds: CommonTest.waitTime,
      );
      await CommonTest.enterText(tester, 'description', request.description!);
      await CommonTest.enterDropDown(
        tester,
        'requestType',
        request.requestType!.name,
      );
      await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
      newRequests.add(
        request.copyWith(requestId: CommonTest.getTextField('id0')),
      );
    }
    return newRequests;
  }

  static Future<void> checkRequest(
    WidgetTester tester,
    List<FinDoc> requests,
  ) async {
    for (FinDoc request in requests) {
      await CommonTest.doNewSearch(
        tester,
        searchString: request.requestId!,
        seconds: CommonTest.waitTime,
      );
      expect(
        CommonTest.getDropdownSearch('otherCompanyUser'),
        contains(
          toCompanyUser(request.otherUser ?? request.otherCompany)!.name,
        ),
      );
      expect(
        CommonTest.getDropdown('statusDropDown'),
        equals(FinDocStatusVal.created.name),
      );
      expect(
        CommonTest.getTextFormField('description'),
        equals(request.description),
      );
      await CommonTest.tapByKey(tester, 'cancel');
    }
  }

  /// approve requests
  static Future<void> approveRequests(WidgetTester tester) async {
    // default approve
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.request);
  }

  /// complete/post a request related to an order
  static Future<void> completeRequests(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.request,
      status: FinDocStatusVal.completed,
    );
  }

  /// check if a request related to an order  has the status complete
  static Future<void> checkRequestsComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.request);
  }

  /// cancel a request
  static Future<void> deleteLastRequest(WidgetTester tester) async {
    await FinDocTest.cancelLastFinDoc(tester, FinDocType.request);
  }
}
