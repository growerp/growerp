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
