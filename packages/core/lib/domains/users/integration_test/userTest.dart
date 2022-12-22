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

import 'package:core/domains/common/functions/persist_functions.dart';
import 'package:core/domains/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/domains/domains.dart';

class UserTest {
  static Future<void> selectAdministrators(WidgetTester tester) async {
    await selectUsers(tester, 'dbCompany', 'UserListFormAdmin', '2');
  }

  static Future<void> selectEmployees(WidgetTester tester) async {
    await selectUsers(tester, 'dbCompany', 'UserListFormEmployee', '3');
  }

  static Future<void> selectLeads(WidgetTester tester) async {
    await selectUsers(tester, 'dbCrm', 'UserListFormLead', '2');
  }

  static Future<void> selectCustomers(WidgetTester tester) async {
    await selectUsers(tester, 'dbCrm', 'UserListFormCustomer', '3');
  }

  static Future<void> selectSuppliers(WidgetTester tester) async {
    await selectUsers(tester, 'dbOrders', 'UserListFormSupplier', '4');
  }

  static Future<void> selectUsers(WidgetTester tester, String option,
      String formName, String tabNumber) async {
    if (find
        .byKey(Key('HomeFormAuth'))
        .toString()
        .startsWith('zero widgets with key')) {
      await CommonTest.gotoMainMenu(tester);
    }
    await CommonTest.selectOption(tester, option, formName, tabNumber);
  }

  static Future<void> addAdministrators(
      WidgetTester tester, List<User> administrators,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.administrators.isEmpty) {
      await PersistFunctions.persistTest(test.copyWith(
          administrators:
              await enterUserData(tester, administrators, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(test.copyWith(
          administrators: await CheckUser(tester, test.administrators)));
    }
  }

  static Future<void> addEmployees(WidgetTester tester, List<User> employees,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.employees.isEmpty) {
      await PersistFunctions.persistTest(test.copyWith(
          employees: await enterUserData(tester, employees, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(employees: await CheckUser(tester, test.employees)));
    }
  }

  static Future<void> addLeads(WidgetTester tester, List<User> leads,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.leads.isEmpty) {
      await PersistFunctions.persistTest(test.copyWith(
          leads: await enterUserData(tester, leads, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(leads: await CheckUser(tester, test.leads)));
    }
  }

  static Future<void> addCustomers(WidgetTester tester, List<User> customers,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.customers.isEmpty) {
      expect(find.byKey(Key('userItem')), findsNWidgets(0));
      await PersistFunctions.persistTest(test.copyWith(
          customers: await enterUserData(tester, customers, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(customers: await CheckUser(tester, test.customers)));
    }
  }

  static Future<void> addSuppliers(WidgetTester tester, List<User> suppliers,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.suppliers.isEmpty) {
      expect(find.byKey(Key('userItem')), findsNWidgets(0));
      await PersistFunctions.persistTest(test.copyWith(
          suppliers: await enterUserData(tester, suppliers, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(suppliers: await CheckUser(tester, test.suppliers)));
    }
  }

  static Future<List<User>> enterUserData(
      WidgetTester tester, List<User> users, int seq) async {
    List<User> newUsers = [];
    for (User user in users) {
      if (user.partyId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: user.partyId!);
        await CommonTest.tapByKey(tester, 'lastName0');
        expect(CommonTest.getTextField('header').split('#')[1], user.partyId);
      }
      expect(find.byKey(Key('UserDialog${user.userGroup.toString()}')),
          findsOneWidget);
      await CommonTest.enterText(tester, 'firstName', user.firstName!);
      await CommonTest.enterText(tester, 'lastName', user.lastName!);
      var email = user.email!.replaceFirst('XXX', '${seq++}');
      await CommonTest.enterText(tester, 'loginName', email);
      await CommonTest.enterText(tester, 'email', email);
      await CommonTest.drag(tester);
      await CommonTest.enterText(tester, 'telephoneNr', user.telephoneNr!);
      // changing to new company will clear paymentMethod and address
      if (user.userGroup != UserGroup.Admin &&
          user.userGroup != UserGroup.Employee) {
        if ((user.companyPaymentMethod == null &&
                user.companyAddress == null) ||
            // need for new
            user.partyId == null) {
          await CommonTest.enterText(
              tester, 'newCompanyName', user.companyName!);
          await CommonTest.drag(tester);
        }
      }
      if (user.partyId != null) {
        await CommonTest.enterDropDown(
            tester, 'userGroup', user.userGroup.toString());
      }
      await CommonTest.tapByKey(tester, 'updateUser');
      await CommonTest.waitForKey(tester, 'dismiss');
      await CommonTest.waitForSnackbarToGo(tester);
      if (user.companyAddress != null) {
        await CommonTest.doSearch(tester, searchString: user.companyName!);
        await CommonTest.tapByKey(tester, 'name0');
        await CommonTest.updateAddress(tester, user.companyAddress!);
      }
      if (user.companyPaymentMethod != null) {
        await CommonTest.doSearch(tester, searchString: user.companyName!);
        await CommonTest.tapByKey(tester, 'name0');
        await CommonTest.updatePaymentMethod(
            tester, user.companyPaymentMethod!);
      }
      newUsers.add(user.copyWith(email: email, loginName: email));
    }
    return (newUsers);
  }

  static Future<List<User>> CheckUser(
      WidgetTester tester, List<User> users) async {
    List<User> newUsers = [];
    for (User user in users) {
      await CommonTest.doSearch(tester, searchString: user.firstName!);
      // check list
      expect(CommonTest.getTextField('name0'),
          equals('${user.firstName} ${user.lastName}'));
      // check detail
      await CommonTest.tapByKey(tester, 'name0');
      var id = CommonTest.getTextField('header').split('#')[1];
      expect(find.byKey(Key('UserDialog${user.userGroup.toString()}')),
          findsOneWidget);
      expect(CommonTest.getTextFormField('firstName'), equals(user.firstName!));
      expect(CommonTest.getTextFormField('lastName'), equals(user.lastName!));
      expect(CommonTest.getTextFormField('loginName'), equals(user.email!));
      expect(CommonTest.getTextFormField('email'), equals(user.email!));
      expect(CommonTest.getTextFormField('telephoneNr'),
          equals(user.telephoneNr!));
      await CommonTest.drag(tester);
      expect(CommonTest.getDropdown('userGroup'),
          equals(user.userGroup.toString()));
      newUsers.add(user.copyWith(partyId: id));

      if (user.userGroup != UserGroup.Admin &&
          user.userGroup != UserGroup.Employee) {
        if (user.companyAddress == null)
          expect(CommonTest.getTextField('addressLabel'),
              equals('No address yet'));
        else
          await CommonTest.checkAddress(tester, user.companyAddress!);

        if (user.companyPaymentMethod == null)
          expect(CommonTest.getTextField('paymentMethodLabel'),
              equals('No payment methods yet'));
        else
          await CommonTest.checkPaymentMethod(
              tester, user.companyPaymentMethod!);
      }
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return newUsers;
  }

  static Future<void> deleteAdministrators(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.administrators.length;
    if (count != administrators.length) return;
    await deleteUser(tester, count + 1);
    PersistFunctions.persistTest(test.copyWith(
        administrators:
            test.administrators.sublist(0, test.administrators.length - 1)));
  }

  static Future<void> deleteEmployees(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.employees.length;
    if (count != employees.length) return;
    await deleteUser(tester, count);
    PersistFunctions.persistTest(test.copyWith(
        employees: test.employees.sublist(0, test.employees.length - 1)));
  }

  static Future<void> deleteLeads(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.leads.length;
    if (count != leads.length) return;
    await deleteUser(tester, count);
    PersistFunctions.persistTest(
        test.copyWith(leads: test.leads.sublist(0, test.leads.length - 1)));
  }

  static Future<void> deleteCustomers(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.customers.length;
    if (count != customers.length) return;
    await deleteUser(tester, count);
    PersistFunctions.persistTest(test.copyWith(
        customers: test.customers.sublist(0, test.customers.length - 1)));
  }

  static Future<void> deleteSuppliers(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.suppliers.length;
    if (count != suppliers.length) return;
    await deleteUser(tester, count);
    PersistFunctions.persistTest(test.copyWith(
        suppliers: test.suppliers.sublist(0, test.suppliers.length - 1)));
  }

  static Future<void> deleteUser(WidgetTester tester, int count) async {
    expect(find.byKey(Key('userItem')), findsNWidgets(count)); // initial admin
    await CommonTest.tapByKey(tester, 'delete${count - 1}', seconds: 5);
    expect(find.byKey(Key('userItem')), findsNWidgets(count - 1));
  }

  static Future<void> updateAdministrators(
      WidgetTester tester, List<User> administrators) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.administrators[0].firstName == administrators[0].firstName) {
      await PersistFunctions.persistTest(test.copyWith(
          administrators:
              await enterUserData(tester, administrators, test.sequence),
          sequence: test.sequence + 10));
    }
    await CheckUser(tester, test.administrators);
  }

  static Future<void> updateEmployees(
      WidgetTester tester, List<User> employees) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.employees[0].firstName == employees[0].firstName) {
      await PersistFunctions.persistTest(test.copyWith(
          employees: await enterUserData(tester, employees, test.sequence),
          sequence: test.sequence + 10));
    }
    await CheckUser(tester, test.employees);
  }

  static Future<void> updateCustomers(
      WidgetTester tester, List<User> customers) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.customers[0].firstName == customers[0].firstName) {
      await PersistFunctions.persistTest(test.copyWith(
          customers: await enterUserData(tester, customers, test.sequence),
          sequence: test.sequence + 10));
    }
    await CheckUser(tester, test.customers);
  }

  static Future<void> updateSuppliers(
      WidgetTester tester, List<User> suppliers) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.suppliers[0].firstName == suppliers[0].firstName) {
      await PersistFunctions.persistTest(test.copyWith(
          suppliers: await enterUserData(tester, suppliers, test.sequence),
          sequence: test.sequence + 10));
    }
    await CheckUser(tester, test.suppliers);
  }

  static Future<void> updateLeads(WidgetTester tester, List<User> leads) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.leads[0].firstName == leads[0].firstName) {
      await PersistFunctions.persistTest(test.copyWith(
          leads: await enterUserData(tester, leads, test.sequence),
          sequence: test.sequence + 10));
    }
    await CheckUser(tester, test.leads);
  }
}
