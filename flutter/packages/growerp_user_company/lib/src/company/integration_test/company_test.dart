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

class CompanyTest {
  static Future<void> checkCompany(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.company == null) return;
    await checkCompanyFields(tester, test.company!);
  }

  static Future<void> selectCompany(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'tapCompany', 'CompanyForm', '1');
  }

  /// enter company data in company dialog screen.
  /// when the list only contains a single item it is
  /// assumed the detail screen is already shown and need not be created/opened
  static Future<void> enterCompanyData(
      WidgetTester tester, List<Company> inputList) async {
    SaveTest test = await PersistFunctions.getTest();

    if (inputList.length == 1) {
      // if single company: main company test
      test = test.copyWith(companies: [test.company!]);
    }
    // if already done return
    if (test.companies.isNotEmpty &&
        test.companies[0].name == inputList[0].name) {
      return;
    }

    // create new list with partyId from last list from test if not empty
    List<Company> clist = List.of(inputList);
    if (test.companies.isNotEmpty) {
      for (int x = 0; x < test.companies.length; x++) {
        clist[x] = clist[x].copyWith(partyId: test.companies[x].partyId);
      }
    }

    int seq = test.sequence;
    List<Company> newCompanies = [];
    for (Company c in clist) {
      if (clist.length > 1) {
        // single (main) company no selection
        if (c.partyId == null) {
          await CommonTest.tapByKey(tester, 'addNew');
        } else {
          await CommonTest.doSearch(tester, searchString: c.partyId!);
          await CommonTest.tapByKey(tester, 'name0');
          expect(CommonTest.getTextField('header').split('#')[1], c.partyId);
        }
      }

      await CommonTest.enterText(tester, 'companyName', c.name!);
      await CommonTest.enterDropDown(
          tester, 'currency', c.currency?.description ?? '');
      await CommonTest.enterText(tester, 'telephoneNr', c.telephoneNr ?? '');
      if (c.email != null) {
        c = c.copyWith(email: c.email!.replaceFirst('XXX', '${seq++}'));
      }
      await CommonTest.drag(tester);
      await CommonTest.enterText(tester, 'email', c.email ?? '');
      await CommonTest.enterText(tester, 'vatPerc', c.vatPerc.toString());
      await CommonTest.enterText(tester, 'salesPerc', c.salesPerc.toString());
      // if required add address and payment
      if (c.address != null) {
        await updateAddress(tester, c.address!);
      } else {
        if (CommonTest.getTextField('addressLabel') !=
            'No postal address yet') {
          await CommonTest.tapByKey(tester, 'deleteAddress');
        }
      }
      if (c.paymentMethod != null) {
        await updatePaymentMethod(tester, c.paymentMethod!);
      } else {
        if (!CommonTest.getTextField('paymentMethodLabel')
            .startsWith('No payment methods yet')) {
          await CommonTest.tapByKey(tester, 'deletePaymentMethod');
        }
      }
      // add/update company record
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'update', seconds: 5);
      // get partyId if not yet have (not for main company)
      if (clist.length > 1 && c.partyId == null) {
        await CommonTest.doSearch(tester, searchString: c.name!);
        await CommonTest.tapByKey(tester, 'name0');
        var id = CommonTest.getTextField('header').split('#')[1];
        c = c.copyWith(partyId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }
      newCompanies.add(c);
    }
    await PersistFunctions.persistTest(
        test.copyWith(companies: newCompanies, sequence: seq));
    await CommonTest.gotoMainMenu(tester);
  }

  static Future<void> checkCompanyFields(
      WidgetTester tester, Company company) async {
    SaveTest test = await PersistFunctions.getTest();

    for (Company c in test.companies) {
      if (test.companies.length > 1) {
        await CommonTest.doSearch(tester, searchString: c.partyId!);
        await CommonTest.tapByKey(tester, 'name0');
        expect(CommonTest.getTextField('header').split('#')[1], c.partyId);
      }
      expect(CommonTest.getTextFormField('companyName'), equals(c.name!));
      expect(CommonTest.getTextFormField('email'), equals(c.email ?? ''));
      expect(CommonTest.getDropdown('role'),
          equals(c.role != null ? c.role!.toString() : ''));
      expect(CommonTest.getTextFormField('telephoneNr'),
          equals(c.telephoneNr ?? ''));
      expect(CommonTest.getDropdown('currency'),
          equals(c.currency?.description ?? ''));
      expect(CommonTest.getTextFormField('vatPerc'),
          equals(c.vatPerc != null ? c.vatPerc.toString() : '0'));
      expect(CommonTest.getTextFormField('salesPerc'),
          equals(c.salesPerc != null ? c.salesPerc.toString() : '0'));
      expect(
          CommonTest.getTextField('addressLabel'),
          equals(c.address == null
              ? 'No postal address yet'
              : "${c.address!.city} ${c.address!.country}"));
      if (c.address != null) {
        await checkAddress(tester, c.address!);
      }
      expect(
          CommonTest.getTextField('paymentMethodLabel'),
          contains(c.paymentMethod == null
              ? 'No payment methods yet'
              : "${c.paymentMethod!.ccDescription}"));
      if (c.paymentMethod != null) {
        await checkPaymentMethod(tester, c.paymentMethod!);
      }
      if (test.companies.length > 1) {
        await CommonTest.tapByKey(tester, 'cancel');
      }
    }
  }

  static Future<void> updateAddress(
      WidgetTester tester, Address address) async {
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'address');
    await CommonTest.enterText(tester, 'address1', address.address1!);
    await CommonTest.enterText(tester, 'address2', address.address2!);
    await CommonTest.enterText(tester, 'postalCode', address.postalCode!);
    await CommonTest.enterText(tester, 'city', address.city!);
    await CommonTest.drag(tester);
    await CommonTest.enterText(tester, 'province', address.province!);
    await CommonTest.enterDropDownSearch(tester, 'country', address.country!);
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'updateAddress');
    await CommonTest.waitForKey(tester, 'dismiss');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> checkAddress(WidgetTester tester, Address address) async {
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'address');
    expect(
        CommonTest.getTextFormField('address1'), contains(address.address1!));
    expect(
        CommonTest.getTextFormField('address2'), contains(address.address2!));
    expect(CommonTest.getTextFormField('postalCode'),
        contains(address.postalCode));
    expect(CommonTest.getTextFormField('city'), contains(address.city!));
    expect(CommonTest.getTextFormField('province'), equals(address.province!));
    expect(CommonTest.getDropdownSearch('country'), equals(address.country));
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> updatePaymentMethod(
      WidgetTester tester, PaymentMethod paymentMethod) async {
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'paymentMethod');
    await CommonTest.enterDropDown(
        tester, 'cardTypeDropDown', paymentMethod.creditCardType.toString());
    await CommonTest.enterText(
        tester, 'creditCardNumber', paymentMethod.creditCardNumber!);
    await CommonTest.enterText(
        tester, 'expireMonth', paymentMethod.expireMonth!);
    await CommonTest.enterText(tester, 'expireYear', paymentMethod.expireYear!);
    await CommonTest.tapByKey(tester, 'updatePaymentMethod');
    await CommonTest.waitForKey(tester, 'dismiss');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> checkPaymentMethod(
      WidgetTester tester, PaymentMethod paymentMethod) async {
    int length = paymentMethod.creditCardNumber!.length;
    await CommonTest.drag(tester);
    expect(
        CommonTest.getTextField('paymentMethodLabel'),
        contains(
            paymentMethod.creditCardNumber!.substring(length - 4, length)));
    expect(CommonTest.getTextField('paymentMethodLabel'),
        contains('${paymentMethod.expireMonth!}/'));
    expect(CommonTest.getTextField('paymentMethodLabel'),
        contains(paymentMethod.expireYear!));
  }

  static Future<void> deleteCompany(WidgetTester tester) async {
//    SaveTest test = await PersistFunctions.getTest();
  }

  static Future<void> employeeCompany(WidgetTester tester) async {
//    SaveTest test = await PersistFunctions.getTest();
  }
}
