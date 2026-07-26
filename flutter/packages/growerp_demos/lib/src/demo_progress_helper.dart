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

import 'package:shared_preferences/shared_preferences.dart';

/// Generic per-demo progress tracker backed by SharedPreferences.
///
/// Each demo is identified by a unique [demoId] string prefix so that
/// multiple demos can coexist without key collisions. All keys are also
/// scoped by [ownerPartyId] so each tenant has independent progress.
///
/// Usage:
/// ```dart
/// final progress = DemoProgressHelper('mfg_demo');
/// DemoEntry(
///   getProgress: progress.getCurrentStep,
///   resetProgress: progress.reset,
///   ...
/// )
/// ```
class DemoProgressHelper {
  final String demoId;

  const DemoProgressHelper(this.demoId);

  String _stepKey(String ownerPartyId) => '${demoId}_step_$ownerPartyId';
  String _soIdKey(String ownerPartyId) => '${demoId}_so_id_$ownerPartyId';
  String _poIdKey(String ownerPartyId) => '${demoId}_po_id_$ownerPartyId';

  Future<int> getCurrentStep(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepKey(ownerPartyId)) ?? 0;
  }

  Future<void> saveStep(int step, String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepKey(ownerPartyId), step);
  }

  Future<void> saveSalesOrderId(String id, String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soIdKey(ownerPartyId), id);
  }

  Future<String?> getSalesOrderId(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_soIdKey(ownerPartyId));
  }

  Future<void> savePurchaseOrderId(String id, String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_poIdKey(ownerPartyId), id);
  }

  Future<String?> getPurchaseOrderId(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_poIdKey(ownerPartyId));
  }

  Future<void> reset(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stepKey(ownerPartyId));
    await prefs.remove(_soIdKey(ownerPartyId));
    await prefs.remove(_poIdKey(ownerPartyId));
  }
}
