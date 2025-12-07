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
import 'src/application/application.dart';

/// Registry to map backend widget names to actual Flutter widgets
class WidgetRegistry {
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]) {
    switch (widgetName) {
      case 'CompanyList':
        return CompanyList(
          key: _getKey(args),
          mainOnly: true,
          role: Role.unknown,
        );
      case 'ApplicationList':
        return const ApplicationList();
      case 'RestRequestList':
        return const RestRequestList();

      default:
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
}
