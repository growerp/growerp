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
import 'forms/@forms.dart';

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> generateRoute(RouteSettings settings) {
  print(">>>NavigateTo { ${settings.name} " +
      "with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case HomeRoute:
      return MaterialPageRoute(
          builder: (context) => AdminHome(settings.arguments));
    case UserRoute:
      return MaterialPageRoute(
          builder: (context) => UserForm(settings.arguments));
    case LoginRoute:
      return MaterialPageRoute(
          builder: (context) => LoginForm(settings.arguments));
    case RegisterRoute:
      return MaterialPageRoute(
          builder: (context) => RegisterForm(settings.arguments));
    case ChangePwRoute:
      return MaterialPageRoute(
          builder: (context) => ChangePwForm(changePwArgs: settings.arguments));
    case AboutRoute:
      return MaterialPageRoute(builder: (context) => AboutForm());
    case CompanyRoute:
      return MaterialPageRoute(
          builder: (context) => CompanyForm(settings.arguments));
    case UsersRoute:
      return MaterialPageRoute(
          builder: (context) => UsersForm(settings.arguments));
    case ProductsRoute:
      return MaterialPageRoute(
          builder: (context) => ProductsForm(settings.arguments));
    case ProductRoute:
      return MaterialPageRoute(
          builder: (context) => ProductForm(settings.arguments));
    case CategoriesRoute:
      return MaterialPageRoute(
          builder: (context) => CategoriesForm(settings.arguments));
    case CategoryRoute:
      return MaterialPageRoute(
          builder: (context) => CategoryForm(settings.arguments));
    case OrdersRoute:
      return MaterialPageRoute(
          builder: (context) => OrdersForm(settings.arguments));
    case OrderRoute:
      return MaterialPageRoute(
          builder: (context) => OrderForm(settings.arguments));
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(settings.name));
  }
}
