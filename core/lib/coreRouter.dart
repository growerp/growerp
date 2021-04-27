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

import 'package:core/forms/@forms.dart';
import 'package:core/templates/@templates.dart';
import 'package:flutter/material.dart';
import 'acctMenuItem_data.dart';
import 'forms/@forms.dart';
import 'package:models/@models.dart';

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> coreRoute(RouteSettings settings) {
  print(">>>NavigateTo { ${settings.name} " +
      "with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case '/company':
      return MaterialPageRoute(
          builder: (context) =>
              CompanyInfoForm(settings.arguments as FormArguments));
    case '/login':
      return MaterialPageRoute(
          builder: (context) => LoginForm(settings.arguments as String?));
    case '/register':
      return MaterialPageRoute(
          builder: (context) => RegisterForm(settings.arguments as String?));
    case '/changePw':
      return MaterialPageRoute(
          builder: (context) =>
              ChangePwForm(changePwArgs: settings.arguments as ChangePwArgs?));
    case '/accounting':
      return MaterialPageRoute(builder: (context) => AccountingForm());
    case '/acctSales':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuItem(
              menuList: acctMenuItems, menuIndex: 1, tabIndex: 0));
    case '/acctPurchase':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuItem(
              menuList: acctMenuItems, menuIndex: 2, tabIndex: 0));
    case '/ledger':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuItem(
              menuList: acctMenuItems, menuIndex: 3, tabIndex: 0));
    case '/about':
      return MaterialPageRoute(builder: (context) => AboutForm());
    case '/printer':
      return MaterialPageRoute(
          builder: (context) =>
              PrintingForm(formArguments: settings.arguments as FormArguments));
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(
              "Routing not found for request: ${settings.name}"));
  }
}
