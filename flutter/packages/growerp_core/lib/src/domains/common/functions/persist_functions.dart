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
import 'package:hive/hive.dart';

T getJsonObject<T>(
    String result, T Function(Map<String, dynamic> json) fromJson) {
  return fromJson(json.decode(result) as Map<String, dynamic>);
}

String createJsonObject<T>(
    T object, T Function(String json) Function() toJson) {
  return jsonEncode(toJson());
}

class PersistFunctions {
  static Future<void> persistAuthenticate(
    Authenticate authenticate,
  ) async {
    try {
      var box = await Hive.openBox('growerp');
      await box.delete('authenticate');
      await box.put('authenticate', jsonEncode(authenticate.toJson()));
      if (authenticate.apiKey == null || authenticate.apiKey == '') {
        await box.delete('apiKey');
      }
    } catch (e) {
      debugPrint("????????persist????????? box error: $e");
    }
  }

  static Future<Authenticate?> getAuthenticate() async {
    // ignore informaton with a bad format
    try {
      var box = await Hive.openBox('growerp');
      String? result = box.get('authenticate');
      if (result != null) {
        return Authenticate.fromJson({'authenticate': jsonDecode(result)});
      }
      return null;
    } catch (e) {
      debugPrint("????????get????????? box error: $e");
      return null;
    }
  }

  static Future<void> removeAuthenticate() async {
    var box = await Hive.openBox('growerp');
    await box.delete('authenticate');
  }

  static Future<void> persistFinDoc(FinDoc finDoc) async {
    var box = await Hive.openBox('growerp');
    await box.put('${finDoc.sales.toString}${finDoc.docType}',
        finDoc.toJson().toString());
  }

  static Future<FinDoc?> getFinDoc(bool sales, FinDocType finDocType) async {
    var box = await Hive.openBox('growerp');
    // ignore informaton with a bad format
    try {
      String? result = box.get('${sales.toString}$finDocType');
      if (result != null) {
        return getJsonObject<FinDoc>(result, (json) => FinDoc.fromJson(json));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeFinDoc(FinDoc finDoc) async {
    var box = await Hive.openBox('growerp');
    await box.delete('${finDoc.sales.toString}${finDoc.docType}');
  }

  static const String _testName = "savetest";
  static Future<void> persistTest(SaveTest test, {bool backup = false}) async {
    var box = await Hive.openBox('growerp');
    await box.put(_testName, jsonEncode(test.toJson()));
  }

  static Future<SaveTest> getTest({bool backup = false}) async {
    var box = await Hive.openBox('growerp');
    // ignore informaton with a bad format
    try {
      String? result = box.get(_testName);
      if (result != null) {
        return getJsonObject<SaveTest>(
            result, (json) => SaveTest.fromJson(json));
      }
      return SaveTest();
    } catch (err) {
      return SaveTest();
    }
  }

  static Future<void> removeTest() async {
    var box = await Hive.openBox('growerp');
    await box.delete(_testName);
  }
}
