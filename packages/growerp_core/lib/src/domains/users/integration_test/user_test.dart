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

import '../../common/functions/persist_functions.dart';
import '../../integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../domains.dart';

class UserTest {
  static Future<void> selectEmployees(WidgetTester tester) async {
    await selectUsers(tester, 'dbCompany', 'UserListFormEmployee', '2');
  }

  static Future<void> selectLeads(WidgetTester tester) async {
    await selectUsers(tester, 'dbCrm', 'UserListFormLead', '2');
  }

  static Future<void> selectCustomers(WidgetTester tester) async {
    await selectUsers(tester, 'dbOrders', 'UserListFormCustomer', '2');
  }

  static Future<void> selectSuppliers(WidgetTester tester) async {
    await selectUsers(tester, 'dbOrders', 'UserListFormSupplier', '4');
  }

  static Future<void> selectUsers(WidgetTester tester, String option,
      String formName, String tabNumber) async {
    if (find
        .byKey(const Key('HomeFormAuth'))
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
              await enterUserData(tester, [], administrators, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(test.copyWith(
          administrators: await checkUser(tester, test.administrators)));
    }
  }

  static Future<void> addEmployees(WidgetTester tester, List<User> employees,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.employees.isEmpty) {
      await PersistFunctions.persistTest(test.copyWith(
          employees: await enterUserData(tester, [], employees, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(employees: await checkUser(tester, test.employees)));
    }
  }

  static Future<void> addLeads(WidgetTester tester, List<User> leads,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.leads.isEmpty) {
      await PersistFunctions.persistTest(test.copyWith(
          leads: await enterUserData(tester, [], leads, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(leads: await checkUser(tester, test.leads)));
    }
  }

  static Future<void> addCustomers(WidgetTester tester, List<User> customers,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.customers.isEmpty) {
      expect(find.byKey(const Key('userItem')), findsNWidgets(0));
      await PersistFunctions.persistTest(test.copyWith(
          customers: await enterUserData(tester, [], customers, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(customers: await checkUser(tester, test.customers)));
    }
  }

  static Future<void> addSuppliers(WidgetTester tester, List<User> suppliers,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.suppliers.isEmpty) {
      expect(find.byKey(const Key('userItem')), findsNWidgets(0));
      await PersistFunctions.persistTest(test.copyWith(
          suppliers: await enterUserData(tester, [], suppliers, test.sequence),
          sequence: test.sequence + 10));
    }
    if (check) {
      test = await PersistFunctions.getTest(backup: false);
      await PersistFunctions.persistTest(
          test.copyWith(suppliers: await checkUser(tester, test.suppliers)));
    }
  }

  static Future<List<User>> enterUserData(WidgetTester tester,
      List<User> oldUsers, List<User> npUsers, int seq) async {
    // copy id's to new list
    if (oldUsers.isNotEmpty) {
      for (int x = 0; x < oldUsers.length; x++) {
        npUsers[x] = npUsers[x].copyWith(partyId: oldUsers[x].partyId);
      }
    }
    List<User> newUsers = [];
    for (User user in npUsers) {
      if (user.partyId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: user.partyId!);
        await CommonTest.tapByKey(tester, 'name0');
        expect(CommonTest.getTextField('header').split('#')[1], user.partyId);
      }
      expect(find.byKey(Key('UserDialog${user.company!.role!.name}')),
          findsOneWidget);
      await CommonTest.enterText(tester, 'firstName', user.firstName!);
      await CommonTest.enterText(tester, 'lastName', user.lastName!);
      String email = '';
      if (user.email != null) {
        email = user.email!.replaceFirst('XXX', '${seq++}');
      }
      await CommonTest.enterText(tester, 'email', email);
      await CommonTest.enterText(tester, 'telephoneNr', user.telephoneNr!);

      await CommonTest.drag(tester);
      // company info
      if (user.company!.role != Role.company) {
        if ((user.company!.paymentMethod == null &&
                user.company!.address == null) ||
            // need for new
            user.partyId == null) {
          await CommonTest.enterText(
              tester, 'newCompanyName', user.company!.name!);
        }
      }
      // login info
      String loginName = '';
      if (user.loginName == null || user.loginName!.isEmpty) {
        await CommonTest.enterText(tester, 'loginName', '');
      } else {
        loginName = user.loginName!.replaceFirst('XXX', '${seq++}');
        await CommonTest.enterText(tester, 'loginName', loginName);
        await CommonTest.enterDropDown(
            tester, 'userGroup', user.userGroup!.name);
        if (user.loginDisabled != null &&
            CommonTest.getCheckbox('loginDisabled') != user.loginDisabled) {
          await CommonTest.tapByKey(tester, 'loginDisabled');
        }
      }
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'updateUser');
      await CommonTest.waitForKey(tester, 'dismiss');
      await CommonTest.waitForSnackbarToGo(tester);
      // if required add address and payment
      if (user.company!.address != null && user.company!.role != Role.company) {
        await CommonTest.doSearch(tester, searchString: user.firstName!);
        await CommonTest.tapByKey(tester, 'name0');
        await CommonTest.updateAddress(tester, user.company!.address!);
      }
      if (user.company!.paymentMethod != null &&
          user.company!.role != Role.company) {
        await CommonTest.doSearch(tester, searchString: user.firstName!);
        await CommonTest.tapByKey(tester, 'name0');
        await CommonTest.updatePaymentMethod(
            tester, user.company!.paymentMethod!);
      }
      newUsers.add(user.copyWith(email: email, loginName: loginName));
    }
    return (newUsers);
  }

  static Future<List<User>> checkUser(
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
      expect(find.byKey(Key('UserDialog${user.company!.role!.name}')),
          findsOneWidget);
      expect(CommonTest.getTextFormField('firstName'), equals(user.firstName!));
      expect(CommonTest.getTextFormField('lastName'), equals(user.lastName!));
      expect(CommonTest.getTextFormField('email'), equals(user.email!));
      expect(CommonTest.getTextFormField('telephoneNr'),
          equals(user.telephoneNr!));
      newUsers.add(user.copyWith(partyId: id));
      await CommonTest.drag(tester);
      // company
      if (user.company!.role != Role.company) {
        if (user.company == null) {
          expect(CommonTest.getTextField('addressLabel'),
              equals('No address yet'));
          expect(CommonTest.getTextField('paymentMethodLabel'),
              equals('No payment methods yet'));
        } else {
          if (user.company!.address != null &&
              user.company!.role != Role.company) {
            await CommonTest.checkAddress(tester, user.company!.address!);
          }
          if (user.company!.paymentMethod != null &&
              user.company!.role != Role.company) {
            await CommonTest.checkPaymentMethod(
                tester, user.company!.paymentMethod!);
          }
        }
      }
      // login
      expect(CommonTest.getTextFormField('loginName'),
          equals(user.loginName ?? ''));
      if (user.loginName != null && user.loginName!.isNotEmpty) {
        expect(CommonTest.getDropdown('userGroup'),
            equals(user.userGroup.toString()));
        if (user.loginDisabled != null) {
          expect(CommonTest.getCheckbox('loginDisabled'),
              equals(user.loginDisabled));
        }
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
    expect(find.byKey(const Key('userItem')),
        findsNWidgets(count)); // initial admin
    await CommonTest.tapByKey(tester, 'delete${count - 1}', seconds: 5);
    expect(find.byKey(const Key('userItem')), findsNWidgets(count - 1));
  }

  static Future<void> updateAdministrators(
      WidgetTester tester, List<User> administrators) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    late SaveTest newTest;
    if (test.administrators[0].firstName != administrators[0].firstName) {
      newTest = test.copyWith(
          administrators: await enterUserData(
              tester, test.administrators, administrators, test.sequence),
          sequence: test.sequence + 10);
      await PersistFunctions.persistTest(newTest);
    } else {
      newTest = test;
    }
    await checkUser(tester, newTest.administrators);
  }

  static Future<void> updateEmployees(
      WidgetTester tester, List<User> employees) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    late SaveTest newTest;
    if (test.employees[0].firstName != employees[0].firstName) {
      newTest = test.copyWith(
          employees: await enterUserData(
              tester, test.employees, employees, test.sequence),
          sequence: test.sequence + 10);
      await PersistFunctions.persistTest(newTest);
    } else {
      newTest = test;
    }
    await checkUser(tester, newTest.employees);
  }

  static Future<void> updateCustomers(
      WidgetTester tester, List<User> customers) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    late SaveTest newTest;
    if (test.customers[0].firstName != customers[0].firstName) {
      newTest = test.copyWith(
          customers: await enterUserData(
              tester, test.customers, customers, test.sequence),
          sequence: test.sequence + 10);
      await PersistFunctions.persistTest(newTest);
    } else {
      newTest = test;
    }
    await checkUser(tester, newTest.customers);
  }

  static Future<void> updateSuppliers(
      WidgetTester tester, List<User> suppliers) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    late SaveTest newTest;
    if (test.suppliers[0].firstName != suppliers[0].firstName) {
      newTest = test.copyWith(
          suppliers: await enterUserData(
              tester, test.suppliers, suppliers, test.sequence),
          sequence: test.sequence + 10);
      await PersistFunctions.persistTest(newTest);
    } else {
      newTest = test;
    }
    await checkUser(tester, newTest.suppliers);
  }

  static Future<void> updateLeads(WidgetTester tester, List<User> leads) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    late SaveTest newTest;
    if (test.leads[0].firstName != leads[0].firstName) {
      newTest = test.copyWith(
          leads: await enterUserData(tester, test.leads, leads, test.sequence),
          sequence: test.sequence + 10);
      await PersistFunctions.persistTest(newTest);
    } else {
      newTest = test;
    }
    await checkUser(tester, newTest.leads);
  }
}
