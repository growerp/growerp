/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the current step of the catalog swag demo across app restarts.
/// All keys are scoped by [ownerPartyId] so each company has independent
/// demo progress.
class DemoProgressService {
  static String _stepKey(String ownerPartyId) =>
      'catalog_swag_demo_step_$ownerPartyId';
  static String _soIdKey(String ownerPartyId) =>
      'catalog_swag_demo_so_id_$ownerPartyId';
  static String _poIdKey(String ownerPartyId) =>
      'catalog_swag_demo_po_id_$ownerPartyId';

  static Future<int> getCurrentStep(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepKey(ownerPartyId)) ?? 0;
  }

  static Future<void> saveStep(int step, String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepKey(ownerPartyId), step);
  }

  static Future<void> saveSalesOrderId(String id, String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soIdKey(ownerPartyId), id);
  }

  static Future<String?> getSalesOrderId(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_soIdKey(ownerPartyId));
  }

  static Future<void> savePurchaseOrderId(
    String id,
    String ownerPartyId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_poIdKey(ownerPartyId), id);
  }

  static Future<String?> getPurchaseOrderId(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_poIdKey(ownerPartyId));
  }

  static Future<void> reset(String ownerPartyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stepKey(ownerPartyId));
    await prefs.remove(_soIdKey(ownerPartyId));
    await prefs.remove(_poIdKey(ownerPartyId));
  }
}
