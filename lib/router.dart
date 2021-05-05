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
import 'routing_constants.dart';
import 'forms/@forms.dart' as local;
import 'package:core/forms/@forms.dart';
import 'package:models/@models.dart';

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> generateRoute(RouteSettings settings) {
  print(">>>NavigateTo { ${settings.name} " +
      "with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case HomeRoute:
      return MaterialPageRoute(
          builder: (context) => local.HomeForm(settings.arguments as String?));
    case LoginRoute:
      return MaterialPageRoute(
          builder: (context) => LoginForm(settings.arguments as String?));
    case RegisterRoute:
      return MaterialPageRoute(
          builder: (context) => RegisterForm(settings.arguments as String?));
    case ChangePwRoute:
      return MaterialPageRoute(
          builder: (context) =>
              ChangePwForm(changePwArgs: settings.arguments as ChangePwArgs?));
    case AboutRoute:
      return MaterialPageRoute(builder: (context) => AboutForm());
    case CartRoute:
      return MaterialPageRoute(builder: (context) => local.CartForm());
    case ProductEcomRoute:
      return MaterialPageRoute(
          builder: (context) =>
              local.ProductForm(settings.arguments as Product?));
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(settings.name!));
  }
}
