/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
    WidgetTester tester,
    List<User> newUsers,
  ) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    expect(
      newUsers.length,
      greaterThanOrEqualTo(test.users.length),
      reason:
          'Number of Users to update (${newUsers.length}) should be at least the number of current users(${test.users.length})',
    );
    int start = newUsers.length - test.users.length;
    await UserTest.updateUsers(
      tester,
      newUsers.sublist(start, start + test.users.length),
      companyUser: true,
    );

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
    WidgetTester tester,
    List<Company> newCompanies,
  ) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    expect(
      newCompanies.length,
      greaterThanOrEqualTo(test.companies.length),
      reason:
          'Number of Companies to update (${newCompanies.length}) should be at least the number of current companies(${test.companies.length}) ',
    );
    int start = newCompanies.length - test.companies.length;
    await CompanyTest.updateCompanies(
      tester,
      newCompanies.sublist(start, start + test.companies.length),
    );
  }

  static Future<void> checkCompaniesUsers(WidgetTester tester) async {
    await UserTest.checkUsers(tester);
    await CompanyTest.checkCompanies(tester);
  }
}
