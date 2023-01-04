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
import 'package:shared_preferences/shared_preferences.dart';
import '../../domains.dart';

List<T> getJsonList<T>(
    String string, T Function(Map<String, dynamic> json) fromJson) {
  final l = json.decode(string) as Iterable;
  return List<T>.from(l.map<T>(
      // ignore: avoid_as, avoid_annotating_with_dynamic
      (dynamic i) => fromJson(i as Map<String, dynamic>)));
}

T getJsonObject<T>(
    String result, T Function(Map<String, dynamic> json) fromJson) {
  return fromJson(json.decode(result) as Map<String, dynamic>);
}

String createJsonList<T>(List<T> result, T Function(String json) toJson()) {
  return jsonEncode(result.map((i) => toJson()).toList()).toString();
}

String createJsonObject<T>(T object, T Function(String json) toJson()) {
  return jsonEncode(toJson());
}

class PersistFunctions {
/*  static Future<void> persistList<T>(List<T> list) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        T.toString(),createJsonList<T>(list, (json) => T.fromJson(json))); 
  }

  static Future<List<T>> getPersistedList<T>() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? result = prefs.getString(T.toString());
    if (result != null)
      return getJsonList<T>(result, (string) => T.toJson(string));
          return Future.value([]);
  }

  static Future<void> persistObject<T>(T object) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(T.toString(), jsonEncode(object));
  }

  static Future<T> getPersistedObject<T>() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? result = prefs.getString(T.toString());
    if (result != null) return jsonDecode(result);
    return Future.value(null);
  }
*/
  static Future<void> persistAuthenticate(
    Authenticate authenticate,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('authenticate', jsonEncode(authenticate.toJson()));
  }

  static Future<Authenticate?> getAuthenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // ignore informaton with a bad format
    try {
      String? result = prefs.getString('authenticate');
      if (result != null)
        return getJsonObject<Authenticate>(
            result, (json) => Authenticate.fromJson(json));
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeAuthenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authenticate');
  }

  static Future<void> persistFinDoc(FinDoc finDoc) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('${finDoc.sales.toString}${finDoc.docType}',
        finDoc.toJson().toString());
  }

  static Future<FinDoc?> getFinDoc(bool sales, FinDocType finDocType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // ignore informaton with a bad format
    try {
      String? result = prefs.getString('${sales.toString}${finDocType}');
      if (result != null)
        return getJsonObject<FinDoc>(result, (json) => FinDoc.fromJson(json));
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeFinDoc(FinDoc finDoc) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('${finDoc.sales.toString}${finDoc.docType}');
  }

  static const String _testName = "savetest";
  static Future<void> persistTest(SaveTest test, {bool backup = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_testName, jsonEncode(test.toJson()));
  }

  static Future<SaveTest> getTest({bool backup = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // ignore informaton with a bad format
    try {
      String? result = prefs.getString(_testName);
      if (result != null)
        return getJsonObject<SaveTest>(
            result, (json) => SaveTest.fromJson(json));
      return SaveTest();
    } catch (_) {
      return SaveTest();
    }
  }

  static Future<void> removeTest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_testName);
  }
}
