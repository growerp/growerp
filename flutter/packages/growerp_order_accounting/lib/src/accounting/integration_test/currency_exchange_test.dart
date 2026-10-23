/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

class CurrencyExchangeTest {
  static Future<void> selectCurrencyExchange(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(
      tester,
      '/accounting/setup/currency-exchange',
      'CurrencyExchangeList',
    );
  }

  /// The rates are central and read only: the list shows, nothing can be added.
  static Future<void> checkReadOnly(WidgetTester tester) async {
    expect(find.byKey(const Key('exchangeRateList')), findsOneWidget);
    expect(find.byKey(const Key('addNew')), findsNothing);
  }
}
