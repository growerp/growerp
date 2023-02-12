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
import 'domains/domains.dart';

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> coreRoute(RouteSettings settings) {
  debugPrint(
      ">>>NavigateTo { ${settings.name} with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case '/company':
      return MaterialPageRoute(builder: (context) => const CompanyForm());
    case '/about':
      return MaterialPageRoute(builder: (context) => const AboutForm());
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(
              message: "Routing not found for request: ${settings.name}"));
  }
}
