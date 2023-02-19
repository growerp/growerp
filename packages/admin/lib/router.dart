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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart' as cat;
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'forms/accounting_form.dart';
import 'acct_menu_option_data.dart';
import 'menu_option_data.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    print('>>>NavigateTo { ${settings.name} '
        'with: ${settings.arguments.toString()} }');
  }
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/company':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/user':
      return MaterialPageRoute(
          builder: (context) =>
              UserForm(user: context.read<Authenticate>().user!));
    case '/crm':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 2, tabIndex: 0));
    case '/catalog':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 3, tabIndex: 0));
    case '/category':
      return MaterialPageRoute(
          builder: (context) =>
              CategoryDialog(settings.arguments as cat.Category));
    case '/orders':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 4, tabIndex: 0));
    case '/inventory':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 5, tabIndex: 0));
    case '/printer':
      return MaterialPageRoute(
          builder: (context) =>
              PrintingForm(finDocIn: settings.arguments as FinDoc));
    case '/accounting':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: acctMenuOptions));
    case '/acctSales':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 1, tabIndex: 0));
    case '/acctPurchase':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 2, tabIndex: 0));
    case '/acctLedger':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 3, tabIndex: 0));
    default:
      return coreRoute(settings);
  }
}
