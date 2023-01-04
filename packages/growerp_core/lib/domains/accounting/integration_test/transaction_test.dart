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

import '../../common/functions/functions.dart';
import '../../../domains/domains.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../common/integration_test/commonTest.dart';

class TransactionTest {
  static Future<void> selectTransactions(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'accntLedger', 'FinDocListFormTransaction', '2');
  }

  static Future<void> checkTransactionComplete(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> finDocs = test.orders.isNotEmpty
        ? test.orders
        : test.invoices.isNotEmpty
            ? test.invoices
            : test.payments;
    for (FinDoc finDoc in finDocs) {
      await CommonTest.doSearch(tester, searchString: finDoc.chainId()!);
      await tester.pumpAndSettle();
      expect(CommonTest.getTextField('status0'), 'Completed',
          reason: 'transaction status field check');
    }
  }
}
