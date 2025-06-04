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
  static Future<void> addUsers(WidgetTester tester, List<User> newUsers) async {
    await UserTest.addUsers(tester, newUsers, companyUser: true);

    // users with a company will now show in the list
    // as a company with an employee
    // remove them from the userlist and add them to the company list
    SaveTest test = await PersistFunctions.getTest(backup: false);
    List<User> users = List.of(test.users);
    List<Company> companies = List.of(test.companies);
    int adjust = 0;
    for (int index = 0; index < test.users.length; index++) {
      if (test.users[index].company?.name != null) {
        companies.add(test.users[index].company!);
        users.removeAt(index - adjust++);
      }
    }
    test = test.copyWith(companies: companies, users: users);
    await PersistFunctions.persistTest(test);
  }

  static Future<void> updateUsers(
      WidgetTester tester, List<User> newUsers) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    expect(newUsers.length, greaterThanOrEqualTo(test.users.length),
        reason:
            'Number of Users to update (${newUsers.length}) should be at least the number of current users(${test.users.length})');
    int start = newUsers.length - test.users.length;
    await UserTest.updateUsers(
        tester,
        newUsers.sublist(
          start,
          start + test.users.length,
        ),
        companyUser: true);

    // users with a company will now show in the list
    // as a company with an employee
    // remove them from the userlist and add them to the company list
    test = await PersistFunctions.getTest(backup: false);
    List<User> users = List.of(test.users);
    List<Company> companies = List.of(test.companies);
    int adjust = 0;
    for (int index = 0; index < test.users.length; index++) {
      if (test.users[index].company?.name != null) {
        companies.add(test.users[index].company!);
        users.removeAt(index - adjust++);
      }
    }
    test = test.copyWith(companies: companies, users: users);
    await PersistFunctions.persistTest(test);
  }

  static Future<void> updateCompanies(
      WidgetTester tester, List<Company> newCompanies) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    expect(newCompanies.length, greaterThanOrEqualTo(test.companies.length),
        reason:
            'Number of Companies to update (${newCompanies.length}) should be at least the number of current companies(${test.companies.length}) ');
    int start = newCompanies.length - test.companies.length;
    await CompanyTest.updateCompanies(
        tester, newCompanies.sublist(start, start + test.companies.length));
  }

  static Future<void> checkCompaniesUsers(
    WidgetTester tester,
  ) async {
    await UserTest.checkUsers(tester);
    await CompanyTest.checkCompanies(tester);
  }
}
