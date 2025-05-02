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

import 'package:flutter/foundation.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/foundation.dart' as debug;
import 'package:flutter/material.dart';

import 'menu_options.dart';
import 'src/application/application.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  if (debug.kDebugMode) {
    if (kDebugMode) {
      debugPrint('>>>NavigateTo { ${settings.name} '
          'with: ${settings.arguments.toString()} }');
    }
  }
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          settings: settings, builder: (context) => const ApplicationList());
    case '/applications':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 1));
    default:
      return coreRoute(settings);
  }
}
