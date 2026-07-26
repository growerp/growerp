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

import 'dart:convert';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'marketing_test_model.dart';

class PersistMarketingTest {
  static const String _testName = "MarketingTest";
  static Future<void> save(MarketingTest test, {bool backup = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_testName, jsonEncode(test.toJson()));
  }

  static Future<MarketingTest> get({bool backup = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // ignore informaton with a bad format
    try {
      String? result = prefs.getString(_testName);
      if (result != null) {
        return getJsonObject<MarketingTest>(
          result,
          (json) => MarketingTest.fromJson(json),
        );
      }
      return MarketingTest();
    } catch (_) {
      return MarketingTest();
    }
  }
}
