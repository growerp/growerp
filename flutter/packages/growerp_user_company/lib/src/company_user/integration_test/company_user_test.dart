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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../company/integration_test/company_test.dart';
import '../../user/integration_test/user_test.dart';

class CompanyUserTest {
  static Future<void> addUsers(
      WidgetTester tester, Role role, List<User> inputList) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    await PersistFunctions.persistTest(test.copyWith(
        leads: role == Role.lead
            ? await UserTest.enterUserData(tester, [], inputList, test.sequence)
            : test.leads,
        suppliers: role == Role.supplier
            ? await UserTest.enterUserData(tester, [], inputList, test.sequence)
            : test.suppliers,
        customers: role == Role.customer
            ? await UserTest.enterUserData(tester, [], inputList, test.sequence)
            : test.customers,
        sequence: test.sequence + 10));
  }

  static Future<void> addCompanies(
      WidgetTester tester, Role role, List<Company> inputList) async {
    await CompanyTest.enterCompanyData(tester, inputList);
  }

  static Future<void> updateUsers(
      WidgetTester tester, Role role, List<User> newInputList) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    List<User> inputList;
    switch (role) {
      case Role.lead:
        inputList = test.leads;
      case Role.customer:
        inputList = test.customers;
      case Role.supplier:
        inputList = test.suppliers;
      default:
        inputList = [];
    }
    await PersistFunctions.persistTest(test.copyWith(
        leads: role == Role.lead
            ? await UserTest.enterUserData(tester, [], inputList, test.sequence)
            : test.leads,
        suppliers: role == Role.supplier
            ? await UserTest.enterUserData(tester, [], inputList, test.sequence)
            : test.suppliers,
        customers: role == Role.customer
            ? await UserTest.enterUserData(tester, [], inputList, test.sequence)
            : test.customers,
        sequence: test.sequence + 10));
  }

  static Future<void> updateCompanies(
      WidgetTester tester, Role role, List<Company> inputList) async {
    await CompanyTest.enterCompanyData(tester, inputList);
  }

  static Future<void> checkCompaniesUsers(
    WidgetTester tester,
    Role role,
  ) async {
    await CompanyTest.checkCompanyFields(tester, Company());
    SaveTest test = await PersistFunctions.getTest(backup: false);
    List<User> inputList;
    switch (role) {
      case Role.lead:
        inputList = test.leads;
      case Role.customer:
        inputList = test.customers;
      case Role.supplier:
        inputList = test.suppliers;
      default:
        inputList = [];
    }
    await UserTest.checkUser(tester, inputList);
  }
}
