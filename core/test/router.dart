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

import 'package:flutter/material.dart';
import 'package:core/forms/@forms.dart';

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> generateRoute(RouteSettings settings) {
  print(">>>NavigateTo { ${settings.name} " +
      "with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case '/login':
      return MaterialPageRoute(
          builder: (context) => LoginForm(settings.arguments as String?));
    case '/register':
      return MaterialPageRoute(
          builder: (context) => RegisterForm(settings.arguments as String?));
    case '/changepw':
      return MaterialPageRoute(
          builder: (context) => ChangePwForm(changePwArgs: settings.arguments as ChangePwArgs?));
    case '/about':
      return MaterialPageRoute(builder: (context) => AboutForm());
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(
              "Routing not found for request: ${settings.name}"));
  }
}
