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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_website/growerp_website.dart';
import 'views/main_menu_form.dart';

/// Registry to map backend widget names to actual Flutter widgets for Health app
class WidgetRegistry {
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]) {
    switch (widgetName) {
      // Dashboard
      case 'AdminDbForm':
      case 'HealthDashboard':
        return const AdminDbForm();

      // Users
      case 'UserListCustomer':
        return UserList(key: _getKey(args), role: Role.customer);
      case 'UserListCompany':
        return UserList(key: _getKey(args), role: Role.company);
      case 'UserList':
        return UserList(key: _getKey(args), role: _parseRole(args?['role']));

      // Company
      case 'ShowCompanyDialog':
        return ShowCompanyDialog(Company(), dialog: false);

      // Website
      case 'WebsiteDialog':
        return const WebsiteDialog();

      // Financial Documents - Request variant
      case 'FinDocListRequest':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.request,
        );

      // Generic FinDocList
      case 'FinDocList':
        return FinDocList(
          key: _getKey(args),
          sales: args?['sales'] ?? true,
          docType: _parseFinDocType(args?['docType']),
        );

      // Core / Misc
      case 'AboutForm':
        return const AboutForm();

      default:
        // Default fallback for unknown widgets
        debugPrint('WidgetRegistry: Widget $widgetName not found');
        return Center(child: Text("Widget $widgetName not found"));
    }
  }

  static Key? _getKey(Map<String, dynamic>? args) {
    if (args != null && args.containsKey('key')) {
      return Key(args['key']);
    }
    return null;
  }

  static Role _parseRole(String? roleName) {
    if (roleName == null) return Role.unknown;
    try {
      return Role.values.firstWhere(
        (e) => e.name.toLowerCase() == roleName.toLowerCase(),
        orElse: () => Role.unknown,
      );
    } catch (_) {
      return Role.unknown;
    }
  }

  static FinDocType _parseFinDocType(String? typeName) {
    if (typeName == null) return FinDocType.unknown;
    try {
      return FinDocType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeName.toLowerCase(),
        orElse: () => FinDocType.unknown,
      );
    } catch (_) {
      return FinDocType.unknown;
    }
  }
}
