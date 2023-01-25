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

import '../../common/functions/functions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../domains.dart';
import '../../integration_test.dart';

class CompanyTest {
  static Future<void> createCompany(WidgetTester tester,
      {bool demoData = false}) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = test.sequence + 1;
    if (test.company != null) return; // company already created
    await CommonTest.logout(tester);
    // tap new company button, enter data
    /// [newCompany]
    await CommonTest.tapByKey(tester, 'newCompButton');
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.enterText(tester, 'firstName', admin.firstName!);
    await CommonTest.enterText(tester, 'lastName', admin.lastName!);
    var email = admin.email!.replaceFirst('XXX', '${seq++}');
    await CommonTest.enterText(tester, 'email', email);

    /// [newCompany]
    String companyName = '${company.name!} ${seq++}';
    await CommonTest.enterText(tester, 'companyName', companyName);
    await CommonTest.drag(tester);
    if (demoData == false) {
      await CommonTest.tapByKey(tester, 'demoData');
    } // no demo data
    await CommonTest.tapByKey(tester, 'newCompany', seconds: 10);
    // start with clean saveTest
    await PersistFunctions.persistTest(SaveTest(
        sequence: seq,
        nowDate: DateTime.now(), // used in rental
        admin: admin.copyWith(email: email, loginName: email),
        company: company.copyWith(email: email, name: companyName)));
    await CommonTest.login(tester);
  }

  static Future<void> selectCompany(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'tapCompany', 'CompanyForm', '1');
  }

  static Future<void> updateCompany(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = test.sequence;
    checkCompanyFields(test.company!, perc: false);
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'update');
    checkCompanyFields(test.company!, perc: false);
    // add a '1' to all fields
    var email = company.email!.replaceFirst('XXX', '${seq++}');
    Company newCompany = Company(
        name: '${company.name!}1',
        email: email,
        currency: currencies[1],
        telephoneNr: '9999999999',
        vatPerc: company.vatPerc! + Decimal.parse('1'),
        salesPerc: company.salesPerc! + Decimal.parse('1'));
    await CommonTest.enterText(tester, 'companyName', newCompany.name!);
    await CommonTest.enterText(tester, 'email', newCompany.email!);
    await CommonTest.enterText(tester, 'telephoneNr', newCompany.telephoneNr!);
    await CommonTest.enterDropDown(
        tester, 'currency', currencies[1].description!);
    await CommonTest.enterText(
        tester, 'vatPerc', newCompany.vatPerc.toString());
    await CommonTest.enterText(
        tester, 'salesPerc', newCompany.salesPerc.toString());
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'update', seconds: 5);
    // get data from server
    await CommonTest.gotoMainMenu(tester);
    await CompanyTest.selectCompany(tester);
    // and check them
    checkCompanyFields(newCompany);
    var id = CommonTest.getTextField('header').split('#')[1];
    await PersistFunctions.persistTest(test.copyWith(
        company: newCompany.copyWith(partyId: id), sequence: seq));
  }

  /// check company fields however not when perc == false: \
  /// no perc fields and telephone because not populated initially
  static void checkCompanyFields(Company company, {bool perc = true}) {
    expect(CommonTest.getTextFormField('companyName'), equals(company.name!));
    expect(CommonTest.getTextFormField('email'), equals(company.email));
    expect(CommonTest.getTextFormField('telephoneNr'),
        equals(perc ? company.telephoneNr : ''));
    expect(CommonTest.getDropdown('currency'),
        equals(company.currency?.description));
    expect(CommonTest.getTextFormField('vatPerc'),
        equals(perc ? company.vatPerc.toString() : ''));
    expect(CommonTest.getTextFormField('salesPerc'),
        equals(perc ? company.salesPerc.toString() : ''));
    expect(CommonTest.getTextField('addressLabel'), equals('No address yet'));
    expect(CommonTest.getTextField('paymentMethodLabel'),
        equals('No payment methods yet'));
  }

  static Future<void> updateAddress(WidgetTester tester,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    await CommonTest.updateAddress(tester, company.address!);
    if (check == true) {
      await CommonTest.checkAddress(tester, company.address!);
      Company newCompany = company.copyWith(
          address: Address(
              address1: '${company.address!.address1!}u',
              address2: '${company.address!.address2!}u',
              postalCode: '${company.address!.postalCode!}u',
              city: '${company.address!.city!}u',
              province: '${company.address!.province!}u',
              country: countries[1].name));
      await CommonTest.drag(tester);
      await CommonTest.updateAddress(tester, newCompany.address!);
      await CommonTest.checkAddress(tester, newCompany.address!);

      await PersistFunctions.persistTest(test.copyWith(company: newCompany));
    } else {
      await PersistFunctions.persistTest(test.copyWith(company: company));
    }
  }

  static Future<void> updatePaymentMethod(WidgetTester tester,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    await CommonTest.updatePaymentMethod(tester, company.paymentMethod!);
    if (check == true) {
      await CommonTest.checkPaymentMethod(tester, company.paymentMethod!);
      Company newCompany = company.copyWith(
          paymentMethod: PaymentMethod(
        creditCardType: CreditCardType.visa,
        creditCardNumber: '4242424242424242',
        expireMonth: '5',
        expireYear: '2025',
      ));
      await CommonTest.drag(tester);
      await CommonTest.updatePaymentMethod(tester, newCompany.paymentMethod!);
      await CommonTest.checkPaymentMethod(tester, newCompany.paymentMethod!);
      await PersistFunctions.persistTest(test.copyWith(company: newCompany));
    } else {
      await PersistFunctions.persistTest(test.copyWith(company: company));
    }
  }
}
