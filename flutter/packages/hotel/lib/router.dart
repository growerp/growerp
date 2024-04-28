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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';
import 'acct_menu_option_data.dart';
import 'menu_option_data.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  debugPrint(
      ">>>NavigateTo { ${settings.name} with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 0, tabIndex: 0));
    case '/company':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              ShowCompanyDialog(settings.arguments as Company));
    case '/user':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => UserDialog(settings.arguments as User));
    case '/myHotel':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/customers':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 5, tabIndex: 0));
    case '/admins':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 1));
    case '/employees':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 2));
    case '/rooms':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 2, tabIndex: 0));
    case '/reservations':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 3, tabIndex: 0));
    case '/checkInOut':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 4, tabIndex: 0));
    case '/accounting':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => HomeForm(menuOptions: acctMenuOptions));
    case '/acctSales':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 1, tabIndex: 0));
    case '/acctPurchase':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 2, tabIndex: 0));
    case '/acctLedger':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 3, tabIndex: 0));
    case '/acctReports':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 4, tabIndex: 0));
    case '/printer':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              PrintingForm(finDocIn: settings.arguments as FinDoc));
    case '/acctSetup':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 5, tabIndex: 0));
    default:
      return coreRoute(settings);
  }
}
