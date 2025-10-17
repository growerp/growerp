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
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/src/company/integration_test/company_test.dart';

class UserTest {
  static Future<void> selectEmployees(WidgetTester tester) async {
    await selectUsers(tester, 'dbCompany', 'UserListEmployee', '2');
  }

  static Future<void> selectLeads(WidgetTester tester) async {
    await selectUsers(tester, 'dbCrm', 'UserListLead', '2');
  }

  static Future<void> selectCustomers(WidgetTester tester) async {
    await selectUsers(tester, 'dbOrders', 'UserListCustomer', '2');
  }

  static Future<void> selectSuppliers(WidgetTester tester) async {
    await selectUsers(tester, 'dbOrders', 'UserListSupplier', '4');
  }

  static Future<void> selectUsers(
    WidgetTester tester,
    String option,
    String formName,
    String tabNumber,
  ) async {
    if (find
        .byKey(const Key('HomeFormAuth'))
        .toString()
        .startsWith('Found 0 widgets with key')) {
      await CommonTest.gotoMainMenu(tester);
    }
    await CommonTest.selectOption(tester, option, formName, tabNumber);
  }

  static Future<void> addUsers(
    WidgetTester tester,
    List<User> users, {
    bool check = true,
    bool companyUser = false,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(users: users));
    await enterUserData(tester, companyUser: companyUser);
  }

  static Future<void> updateUsers(
    WidgetTester tester,
    List<User> newUsers, {
    bool companyUser = false,
  }) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy pseudo id to new data
    for (int x = 0; x < newUsers.length; x++) {
      newUsers[x] = newUsers[x].copyWith(pseudoId: old.users[x].pseudoId);
      if (newUsers[x].company != null) {
        Company newCompany = newUsers[x].company!.copyWith(
          pseudoId: old.users[x].company?.pseudoId,
        );
        newUsers[x] = newUsers[x].copyWith(company: newCompany);
      }
    }
    await PersistFunctions.persistTest(old.copyWith(users: newUsers));
    await enterUserData(tester, companyUser: companyUser);
  }

  static Future<void> deleteUsers(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.users.length;
    // employees have an extra initial admin
    if (test.users.last.role == Role.company) {
      count++;
    }
    expect(
      find.byKey(const Key('userItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('userItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    PersistFunctions.persistTest(
      test.copyWith(users: test.users.sublist(0, count - 2)),
    );
  }

  static Future<void> enterUserData(
    WidgetTester tester, {
    // if called from companyUser list
    bool companyUser = false,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = test.sequence;
    List<User> newUsers = [];
    for (User user in test.users) {
      if (user.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'addNewUser');
      } else {
        await CommonTest.doNewSearch(tester, searchString: user.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          user.pseudoId,
        );
      }
      expect(find.byKey(Key('UserDialog${user.role!.name}')), findsOneWidget);
      await CommonTest.enterText(tester, 'firstName', user.firstName!);
      await CommonTest.enterText(tester, 'lastName', user.lastName!);

      if (user.email != null) {
        user = user.copyWith(
          email: user.email!.replaceFirst('XXX', '${seq++}'),
        );
      }
      await CommonTest.enterText(tester, 'userEmail', user.email ?? '');

      if (user.url != null) {
        user = user.copyWith(url: user.url!.replaceFirst('XXX', '${seq++}'));
      }
      await CommonTest.enterText(tester, 'userUrl', user.url ?? '');

      await CommonTest.enterText(
        tester,
        'userTelephoneNr',
        user.telephoneNr ?? '',
      );

      // if required add address and payment
      await CommonTest.dragUntil(
        tester,
        key: 'addressLabel',
        listViewName: 'userDialogListView',
      );
      if (user.address != null) {
        await CompanyTest.updateAddress(tester, user.address!);
      } else {
        if (CommonTest.getTextField('addressLabel') !=
            'No postal address yet') {
          await CommonTest.tapByKey(tester, 'deleteAddress');
        }
      }
      await CommonTest.dragUntil(
        tester,
        key: 'paymentMethodLabel',
        listViewName: 'userDialogListView',
      );
      if (user.paymentMethod != null) {
        await CompanyTest.updatePaymentMethod(tester, user.paymentMethod!);
      } else {
        if (!CommonTest.getTextField(
          'paymentMethodLabel',
        ).startsWith('No payment methods yet')) {
          await CommonTest.tapByKey(tester, 'deletePaymentMethod');
        }
      }

      // company info fixed for employees will not show for update
      bool companyAssigned = false;
      if (user.role != Role.company) {
        await CommonTest.drag(tester, listViewName: 'userDialogListView');
        if (user.company?.name == null) {
          if (await CommonTest.doesExistKey(tester, 'removeCompany')) {
            await CommonTest.tapByKey(tester, 'removeCompany');
          }
        } else {
          // check company buttons if company assigned
          if (await CommonTest.doesExistKey(tester, 'newCompany')) {
            await CommonTest.tapByKey(tester, 'newCompany');
            companyAssigned = true;
          } else {
            await CommonTest.tapByKey(tester, 'editCompany');
            expect(
              CommonTest.getTextField('topHeader').split('#')[1],
              user.company!.pseudoId,
            );
          }
          await CommonTest.enterText(
            tester,
            'companyName',
            user.company!.name!,
          ); // required!
          await CommonTest.enterText(
            tester,
            'telephoneNr',
            user.company!.telephoneNr ?? '',
          );
          if (user.company?.email != null) {
            user = user.copyWith(
              company: user.company!.copyWith(
                email: user.company!.email!.replaceFirst('XXX', '${seq++}'),
              ),
            );
          }
          if (user.company?.url != null) {
            user = user.copyWith(
              company: user.company!.copyWith(
                url: user.company!.url!.replaceFirst('XXX', '${seq++}'),
              ),
            );
          }
          await CommonTest.dragUntil(
            tester,
            key: 'email',
            listViewName: 'companyDialogListView',
          );
          await CommonTest.enterText(
            tester,
            'email',
            user.company?.email ?? '',
          );
          await CommonTest.enterText(tester, 'url', user.company?.url ?? '');
          await CommonTest.dragUntil(
            tester,
            key: 'companyDialogUpdate',
            listViewName: 'companyDialogListView',
          );
          await CommonTest.tapByKey(tester, 'companyDialogUpdate');
        }
      }

      if (user.loginName != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'loginName',
          listViewName: 'userDialogListView',
        );
        user = user.copyWith(
          loginName: user.loginName!.replaceFirst('XXX', '${seq++}'),
        );
        await CommonTest.enterText(tester, 'loginName', user.loginName!);
        await CommonTest.enterDropDown(
          tester,
          'userGroup',
          user.userGroup!.name,
        );
        if (user.loginDisabled != null &&
            CommonTest.getCheckbox('loginDisabled') != user.loginDisabled) {
          await CommonTest.tapByKey(tester, 'loginDisabled');
        }
      }
      await CommonTest.dragUntil(
        tester,
        key: 'userDialogUpdate',
        listViewName: 'userDialogListView',
      );
      tester.pumpAndSettle(const Duration(milliseconds: 100));
      await CommonTest.tapByKey(
        tester,
        'userDialogUpdate',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.waitForSnackbarToGo(tester);
      // here the list is shown again
      // get new user pseudoId when adding
      if (user.pseudoId == null || companyAssigned) {
        // new entry is at the top of the list, get allocated ID
        await CommonTest.tapByKey(tester, 'item0');
        var id = CommonTest.getTextField('topHeader').split('#')[1];
        // if this test is called from company_usertest.dart
        // companyUser = true
        // and the user has a company, the company dialog shown instead.
        // and the user and employee are switched
        if (companyAssigned) {
          if (companyUser) {
            final dialogExists = await CommonTest.doesExistKey(
              tester,
              'CompanyDialog${user.company!.role!.name}',
            );
            expect(
              dialogExists,
              true,
              reason: "key not found: CompanyDialog${user.company!.role!.name}",
            );
            // company pseudoId
            user = user.copyWith(company: user.company!.copyWith(pseudoId: id));
            var employeeId = CommonTest.getTextField('employee0').split('[')[1];
            // employee pseudoId
            employeeId = employeeId.split(']')[0];
            user = user.copyWith(pseudoId: employeeId);
          } else {
            expect(
              await CommonTest.doesExistKey(
                tester,
                'UserDialog${user.role!.name}',
              ),
              true,
              reason: "key: UserDialog${user.role!.name} not found",
            );
            var companyPseudoId = CommonTest.getDropdownSearch(
              'userCompanyName',
            ).split('[')[1];
            companyPseudoId = companyPseudoId.split(']')[0];
            user = user.copyWith(
              company: user.company!.copyWith(pseudoId: companyPseudoId),
            );
          }
        }
        if (user.pseudoId == null) {
          if (companyAssigned && companyUser) {
            final dialogExists = await CommonTest.doesExistKey(
              tester,
              'CompanyDialog${user.company!.role!.name}',
            );
            expect(
              dialogExists,
              true,
              reason: "key not found: CompanyDialog${user.company!.role!.name}",
            );
          } else {
            expect(
              await CommonTest.doesExistKey(
                tester,
                'UserDialog${user.role!.name}',
              ),
              true,
              reason: "key: UserDialog${user.role!.name} not found",
            );
          }
          // user pseudoId
          user = user.copyWith(pseudoId: id);
        }
        await CommonTest.tapByKey(tester, 'cancel');
      }
      newUsers.add(user);
    }
    await PersistFunctions.persistTest(
      test.copyWith(users: newUsers, sequence: seq),
    );
  }

  static Future<void> checkUsers(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    for (User user in test.users) {
      await CommonTest.doNewSearch(tester, searchString: user.firstName!);
      // check detail
      expect(find.byKey(Key('UserDialog${user.role!.name}')), findsOneWidget);
      expect(CommonTest.getTextFormField('firstName'), equals(user.firstName!));
      expect(CommonTest.getTextFormField('lastName'), equals(user.lastName!));
      expect(
        CommonTest.getTextFormField('userEmail'),
        equals(user.email ?? ''),
      );
      expect(CommonTest.getTextFormField('userUrl'), equals(user.url ?? ''));
      expect(
        CommonTest.getTextFormField('userTelephoneNr'),
        equals(user.telephoneNr ?? ''),
      );

      await CommonTest.dragUntil(tester, key: 'addressLabel');
      expect(
        CommonTest.getTextField('addressLabel'),
        equals(
          user.address == null
              ? 'No postal address yet'
              : "${user.address!.city} ${user.address!.country}",
        ),
      );
      if (user.address != null) {
        await CommonTest.tapByKey(tester, 'address');
        await CompanyTest.checkAddress(tester, user.address!);
      }
      await CommonTest.dragUntil(
        tester,
        key: 'paymentMethodLabel',
        listViewName: 'userDialogListView',
      );
      expect(
        CommonTest.getTextField('paymentMethodLabel'),
        contains(
          user.paymentMethod == null
              ? 'No payment methods yet'
              : "${user.paymentMethod!.ccDescription}",
        ),
      );
      if (user.paymentMethod != null) {
        await CompanyTest.checkPaymentMethod(tester, user.paymentMethod!);
      }

      if (user.role != Role.company) {
        // employees not show company
        if (user.company?.name == null) {
          expect(
            await CommonTest.doesExistKey(tester, 'newCompany'),
            equals(true),
          );
        } else {
          expect(
            await CommonTest.doesExistKey(tester, 'editCompany'),
            equals(true),
            reason:
                'Company ${user.company!.name} not found on user ${user.firstName} ${user.lastName}',
          );
          await CommonTest.dragUntil(
            tester,
            key: 'editCompany',
            listViewName: 'userDialogListView',
          );
          expect(
            CommonTest.getDropdownSearch('userCompanyName'),
            contains(user.company!.name),
          );
          await CommonTest.tapByKey(tester, 'editCompany');
          expect(
            CommonTest.getTextFormField('companyName'),
            equals(user.company!.name!),
          ); // required!
          expect(
            CommonTest.getDropdown('role'),
            equals(user.company!.role.toString()),
          );
          expect(
            CommonTest.getTextFormField('telephoneNr'),
            equals(user.company!.telephoneNr ?? ''),
          );
          expect(
            CommonTest.getTextFormField('email'),
            equals(user.company!.email ?? ''),
          );
          expect(
            CommonTest.getTextFormField('url'),
            equals(user.company!.url ?? ''),
          );
          await CommonTest.tapByKey(tester, 'cancel');
        }
      }
      await CommonTest.dragUntil(
        tester,
        key: 'loginName',
        listViewName: 'userDialogListView',
      );
      // login, check only when login name present, cannot delete userlogin
      if (user.loginName != null && user.loginName!.isNotEmpty) {
        expect(
          CommonTest.getTextFormField('loginName'),
          equals(user.loginName ?? ''),
        );
        expect(
          CommonTest.getDropdown('userGroup'),
          equals(user.userGroup.toString()),
        );
        if (user.loginDisabled != null) {
          expect(
            CommonTest.getCheckbox('loginDisabled'),
            equals(user.loginDisabled),
          );
        }
      }
      await CommonTest.tapByKey(tester, 'cancel');
    }
  }
}
