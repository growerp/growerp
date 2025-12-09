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

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

T getJsonObject<T>(
  String result,
  T Function(Map<String, dynamic> json) fromJson,
) {
  return fromJson(json.decode(result) as Map<String, dynamic>);
}

String createJsonObject<T>(
  T object,
  T Function(String json) Function() toJson,
) {
  return jsonEncode(toJson());
}

class PersistFunctions {
  static Future<void> persistKeyValue(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> removeKey(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> persistAuthenticate(Authenticate authenticate) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('authenticate', jsonEncode(authenticate.toJson()));

      if (authenticate.apiKey == null || authenticate.apiKey == '') {
        await prefs.remove('apiKey');
      }
    } catch (e) {
      debugPrint("????????persist????????? error: $e");
    }
  }

  static Future<Authenticate?> getAuthenticate() async {
    // ignore informaton with a bad format
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? result = prefs.getString('authenticate');
      if (result != null) {
        return Authenticate.fromJson({'authenticate': jsonDecode(result)});
      }
      return null;
    } catch (e) {
      debugPrint("????????get????????? error: $e");
      return null;
    }
  }

  static Future<void> removeAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authenticate');
  }

  static Future<void> persistFinDoc(FinDoc finDoc) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${finDoc.sales.toString}${finDoc.docType}',
      finDoc.toJson().toString(),
    );
  }

  static Future<FinDoc?> getFinDoc(bool sales, FinDocType finDocType) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // ignore informaton with a bad format
    try {
      final String? result = prefs.getString('${sales.toString}$finDocType');
      if (result != null) {
        return getJsonObject<FinDoc>(result, (json) => FinDoc.fromJson(json));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeFinDoc(FinDoc finDoc) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('${finDoc.sales.toString}${finDoc.docType}');
  }

  static const String _testName = "savetest";

  /// Get the persistent directory for test data
  /// Uses application documents directory which persists across test runs
  static Future<String> _getPersistentTestDir() async {
    if (kIsWeb) {
      return '';
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final testDir = Directory('${dir.path}/integration_test_data');
      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }
      return testDir.path;
    } catch (e) {
      debugPrint("Could not get persistent test directory: $e");
      // Fallback to current directory
      return Directory.current.path;
    }
  }

  static Future<void> persistTest(SaveTest test, {bool backup = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_testName, jsonEncode(test.toJson()));
    if (!kIsWeb) {
      try {
        final testDir = await _getPersistentTestDir();
        final file = File('$testDir/$_testName.json');
        await file.writeAsString(jsonEncode(test.toJson()));
      } catch (e) {
        debugPrint("Could not save test to file: $e");
      }
    }
  }

  static Future<SaveTest> getTest({bool backup = false}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? result = prefs.getString(_testName);
      if (result == null && !kIsWeb) {
        try {
          final testDir = await _getPersistentTestDir();
          final file = File('$testDir/$_testName.json');
          if (await file.exists()) {
            result = await file.readAsString();
          }
        } catch (e) {
          debugPrint("Could not read test from file: $e");
        }
      }
      final String? finalResult = result;
      if (finalResult != null) {
        return getJsonObject<SaveTest>(
          finalResult,
          (json) => SaveTest.fromJson(json),
        );
      }
      return SaveTest();
    } catch (err) {
      debugPrint("Error getting test: $err");
      return SaveTest();
    }
  }

  static Future<void> removeTest() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_testName);
  }
}
