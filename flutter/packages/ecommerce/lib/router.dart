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

import 'package:core/coreRouter.dart';
import 'package:core/domains/domains.dart';
import 'package:flutter/material.dart';
import 'forms/@forms.dart' as local;

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> generateRoute(RouteSettings settings) {
  print(">>>NavigateTo { ${settings.name} " +
      "with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => local.HomeForm());
    case '/cart':
      return MaterialPageRoute(builder: (context) => local.CartForm());
    case '/product':
      return MaterialPageRoute(
          builder: (context) =>
              local.ProductForm(settings.arguments as Product?));
    default:
      return coreRoute(settings);
  }
}
