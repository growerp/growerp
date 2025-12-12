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

class CompanyTest {
  static Future<void> selectCompany(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbCompanies', 'CompanyForm', '1');
  }

  static Future<void> addCompanies(
    WidgetTester tester,
    List<Company> companies, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(companies: companies));
    await enterCompanyData(tester);
  }

  static Future<void> updateCompanies(
    WidgetTester tester,
    List<Company> newCompanies,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy pseudo id to new data
    for (int x = 0; x < newCompanies.length; x++) {
      newCompanies[x] = newCompanies[x].copyWith(
        pseudoId: old.companies[x].pseudoId,
      );
      List<User> newEmployees = [];
      for (int y = 0; y < newCompanies[x].employees.length; y++) {
        User newEmployee = newCompanies[x].employees[y].copyWith(
          pseudoId: old.companies[x].employees[y].pseudoId,
        );
        newEmployees.add(newEmployee);
      }
      newCompanies[x] = newCompanies[x].copyWith(employees: newEmployees);
    }
    await PersistFunctions.persistTest(old.copyWith(companies: newCompanies));
    await enterCompanyData(tester);
  }

  /// enter company data in company dialog screen.
  /// when the list only contains a single item it is
  /// assumed the detail screen is already shown and need not be created/opened
  static Future<void> enterCompanyData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();

    // create new list with pseudoId from last list from test if not empty
    List<Company> clist = List.of(test.companies);
    int seq = test.sequence;
    List<Company> newCompanies = [];
    for (Company c in clist) {
      if (clist.length > 1) {
        // single (main) company no selection
        if (c.pseudoId == null) {
          await CommonTest.tapByKey(tester, 'addNewCompany');
        } else {
          await CommonTest.doNewSearch(tester, searchString: c.pseudoId!);
          expect(
            CommonTest.getTextField('topHeader').split('#')[1],
            c.pseudoId,
          );
        }
      }

      await CommonTest.enterText(tester, 'companyName', c.name!);
      if (c.currency != null) {
        await CommonTest.enterDropDown(
          tester,
          'currency',
          c.currency?.description ?? '',
        );
      }
      await CommonTest.enterText(tester, 'telephoneNr', c.telephoneNr ?? '');
      await CommonTest.dragNew(tester, key: 'companyDialogListView');

      if (c.email != null && c.email!.isNotEmpty) {
        c = c.copyWith(email: c.email!.replaceFirst('XXX', '${seq++}'));
      }
      await CommonTest.enterText(tester, 'email', c.email ?? '');

      if (c.url != null && c.url!.isNotEmpty) {
        c = c.copyWith(url: c.url!.replaceFirst('XXX', '${seq++}'));
      }
      await CommonTest.enterText(tester, 'url', c.url ?? '');

      if (c.role == Role.company) {
        await CommonTest.enterText(tester, 'vatPerc', c.vatPerc.toString());
        await CommonTest.enterText(tester, 'salesPerc', c.salesPerc.toString());
      }
      // if required add address and payment
      if (c.address != null) {
        await CommonTest.drag(tester, listViewName: 'companyDialogListView');
        await updateAddress(tester, c.address!);
      } else {
        if (CommonTest.getTextField('addressLabel') !=
            'No postal address yet') {
          await CommonTest.tapByKey(tester, 'deleteAddress');
        }
      }
      if (c.paymentMethod != null) {
        await CommonTest.drag(tester, listViewName: 'companyDialogListView');
        await updatePaymentMethod(tester, c.paymentMethod!);
      } else {
        if (!CommonTest.getTextField(
          'paymentMethodLabel',
        ).startsWith('No payment methods yet')) {
          await CommonTest.tapByKey(tester, 'deletePaymentMethod');
        }
      }
      await CommonTest.drag(tester, listViewName: 'companyDialogListView');
      // add/update company record
      await CommonTest.tapByKey(
        tester,
        'companyDialogUpdate',
        seconds: CommonTest.waitTime,
      );
      // get generated pseudoId's
      if (clist.length > 1 && c.pseudoId == null) {
        // new entry is at the top of the list, get allocated ID
        await CommonTest.tapByKey(tester, 'item0');
        var id = CommonTest.getTextField('topHeader').split('#')[1];
        c = c.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }
      newCompanies.add(c);
    }
    await PersistFunctions.persistTest(
      test.copyWith(companies: newCompanies, sequence: seq),
    );
  }

  static Future<void> checkCompanies(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();

    for (Company c in test.companies) {
      if (test.companies.length > 1) {
        await CommonTest.doNewSearch(tester, searchString: c.pseudoId!);
        expect(CommonTest.getTextField('topHeader').split('#')[1], c.pseudoId);
      }
      expect(CommonTest.getTextFormField('companyName'), equals(c.name!));
      expect(CommonTest.getTextFormField('email'), equals(c.email ?? ''));
      expect(CommonTest.getTextFormField('url'), equals(c.url ?? ''));
      if (c.role != Role.company) {
        // main company role one cannot change
        expect(
          CommonTest.getDropdown('role'),
          equals(c.role != null ? c.role!.toString() : ''),
        );
      }
      expect(
        CommonTest.getTextFormField('telephoneNr'),
        equals(c.telephoneNr ?? ''),
      );
      expect(
        CommonTest.getDropdown('currency'),
        equals(c.currency?.description ?? ''),
      );
      if (c.role == Role.company) {
        expect(
          CommonTest.getTextFormField('vatPerc'),
          equals(c.vatPerc != null ? c.vatPerc.toString() : '0'),
        );
        expect(
          CommonTest.getTextFormField('salesPerc'),
          equals(c.salesPerc != null ? c.salesPerc.toString() : '0'),
        );
        await CommonTest.dragNew(tester, key: 'companyDialogListView');
      }
      await CommonTest.dragUntil(
        tester,
        key: 'addressLabel',
        listViewName: 'companyDialogListView',
      );
      expect(
        CommonTest.getTextField('addressLabel'),
        equals(
          c.address == null
              ? 'No postal address yet'
              : "${c.address!.city} ${c.address!.country}",
        ),
      );
      if (c.address != null) {
        await CommonTest.dragNew(tester, key: 'companyDialogListView');
        await CommonTest.tapByKey(tester, 'address');
        await checkAddress(tester, c.address!);
      }
      await CommonTest.dragUntil(
        tester,
        key: 'paymentMethodLabel',
        listViewName: 'companyDialogListView',
      );
      expect(
        CommonTest.getTextField('paymentMethodLabel'),
        contains(
          c.paymentMethod == null
              ? 'No payment methods yet'
              : "${c.paymentMethod!.ccDescription}",
        ),
      );
      if (c.paymentMethod != null) {
        await checkPaymentMethod(tester, c.paymentMethod!);
      }
      if (test.companies.length > 1) {
        await CommonTest.tapByKey(tester, 'cancel');
      }
    }
  }

  static Future<void> updateAddress(
    WidgetTester tester,
    Address address,
  ) async {
    await CommonTest.tapByKey(tester, 'address');
    await CommonTest.enterText(tester, 'address1', address.address1!);
    await CommonTest.enterText(tester, 'address2', address.address2!);
    await CommonTest.enterText(tester, 'postalCode', address.postalCode!);
    await CommonTest.enterText(tester, 'city', address.city!);
    await CommonTest.dragNew(tester, key: 'addressListView');
    await CommonTest.enterText(tester, 'province', address.province!);
    await CommonTest.enterDropDownSearch(tester, 'country', address.country!);
    await CommonTest.dragNew(tester, key: 'addressListView');
    await CommonTest.tapByKey(tester, 'updateAddress');
    await CommonTest.waitForKey(tester, 'dismiss');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> checkAddress(WidgetTester tester, Address address) async {
    expect(
      CommonTest.getTextFormField('address1'),
      contains(address.address1!),
    );
    expect(
      CommonTest.getTextFormField('address2'),
      contains(address.address2!),
    );
    expect(
      CommonTest.getTextFormField('postalCode'),
      contains(address.postalCode),
    );
    expect(CommonTest.getTextFormField('city'), contains(address.city!));
    expect(CommonTest.getTextFormField('province'), equals(address.province!));
    expect(CommonTest.getDropdownSearch('country'), equals(address.country));
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> updatePaymentMethod(
    WidgetTester tester,
    PaymentMethod paymentMethod,
  ) async {
    await CommonTest.tapByKey(tester, 'paymentMethod');
    await CommonTest.enterDropDown(
      tester,
      'cardTypeDropDown',
      paymentMethod.creditCardType.toString(),
    );
    await CommonTest.enterText(
      tester,
      'creditCardNumber',
      paymentMethod.creditCardNumber!,
    );
    await CommonTest.enterText(
      tester,
      'expireMonth',
      paymentMethod.expireMonth!,
    );
    await CommonTest.enterText(tester, 'expireYear', paymentMethod.expireYear!);
    await CommonTest.tapByKey(tester, 'updatePaymentMethod');
    await CommonTest.waitForKey(tester, 'dismiss');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> checkPaymentMethod(
    WidgetTester tester,
    PaymentMethod paymentMethod,
  ) async {
    int length = paymentMethod.creditCardNumber!.length;
    await CommonTest.tapByKey(tester, 'paymentMethodLabel');
    expect(
      CommonTest.getTextField('paymentMethodLabel'),
      contains(paymentMethod.creditCardNumber!.substring(length - 4, length)),
    );
    expect(
      CommonTest.getTextField('paymentMethodLabel'),
      contains('${paymentMethod.expireMonth!}/'),
    );
    expect(
      CommonTest.getTextField('paymentMethodLabel'),
      contains(paymentMethod.expireYear!),
    );
    await CommonTest.tapByKey(tester, 'cancel');
  }

  Future<void> deleteCompany(WidgetTester tester) async {
    //    SaveTest test = await PersistFunctions.getTest();
  }

  Future<void> employeeCompany(WidgetTester tester) async {
    //    SaveTest test = await PersistFunctions.getTest();
  }
}
