import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:logger/logger.dart';

/// The growerp CLI exports with csvFromX and imports with csvToX: what is
/// exported must import back unchanged.
void main() {
  group('createCsvRow', () {
    test('createCsvRow_values_quotesAndPadsToLength', () {
      // Act
      final row = createCsvRow(['a', '', 'say "hi"', 'x,y'], 6);
      // Assert
      expect(row, '"a",,"say ""hi""","x,y",,,\r\n');
    });
  });

  group('round trips', () {
    test('GlAccountCsv_exportedAccounts_importBackUnchanged', () {
      // Arrange
      final accounts = [
        GlAccount(
          accountCode: '1000',
          accountName: 'Cash, petty',
          isDebit: true,
          accountClass: const AccountClass(description: 'Asset'),
          accountType: AccountType(description: 'Cash'),
          postedBalance: Decimal.parse('150.25'),
        ),
      ];
      // Act
      final imported = csvToGlAccounts(csvFromGlAccounts(accounts));
      // Assert
      final a = imported.single;
      expect(a.accountCode, '1000');
      expect(a.accountName, 'Cash, petty');
      expect(a.isDebit, isTrue);
      expect(a.accountClass?.description, 'Asset');
      expect(a.accountType?.description, 'Cash');
      expect(a.postedBalance, Decimal.parse('150.25'));
    });

    test('UserCsv_exportedUsers_importBackUnchanged', () {
      // Arrange
      final users = [
        User(
          pseudoId: 'u1',
          firstName: 'Jane',
          lastName: 'Roe',
          email: 'jane@acme.com',
          loginName: 'jane',
          telephoneNr: '+66 1',
          userGroup: UserGroup.admin,
          language: 'th',
          image: Uint8List.fromList([1, 2]),
          company: Company(name: 'Acme', role: Role.customer),
        ),
      ];
      // Act
      final u = csvToUsers(csvFromUsers(users)).single;
      // Assert
      expect(
        [u.pseudoId, u.firstName, u.lastName, u.email, u.loginName],
        ['u1', 'Jane', 'Roe', 'jane@acme.com', 'jane'],
      );
      expect(u.telephoneNr, '+66 1');
      expect(u.userGroup, UserGroup.admin);
      expect(u.language, 'th');
      expect(u.image, [1, 2]);
      expect(u.company?.name, 'Acme');
      expect(u.company?.role, Role.customer);
    });

    test('ProductCsv_oneCategory_importsBackUnchanged', () {
      // Arrange
      final products = [
        Product(
          pseudoId: 'p1',
          productTypeId: 'Physical Good',
          productName: 'Apple',
          description: 'Red',
          listPrice: Decimal.parse('1.5'),
          price: Decimal.parse('1.2'),
          useWarehouse: true,
          categories: [Category(categoryName: 'Fruit')],
          image: Uint8List.fromList([3]),
        ),
      ];
      // Act
      final p = csvToProducts(csvFromProducts(products), Logger()).single;
      // Assert
      expect(p.pseudoId, 'p1');
      expect(p.productName, 'Apple');
      expect(p.listPrice, Decimal.parse('1.5'));
      expect(p.price, Decimal.parse('1.2'));
      expect(p.useWarehouse, isTrue);
      expect(p.categories.first.categoryName, 'Fruit');
      expect(p.image, [3]);
    });

    test('ProductCsv_noPrices_importsNullPrices', () {
      // Act
      final p = csvToProducts(
        csvFromProducts([Product(pseudoId: 'p2', productName: 'Free')]),
        Logger(),
      ).single;
      // Assert
      expect(p.listPrice, isNull);
      expect(p.price, isNull);
    });
  });

  // https://github.com/growerp/growerp/issues/47
  group('broken round trips', () {
    test('ProductCsv_twoCategories_keepsBoth', () {
      final p = csvToProducts(
        csvFromProducts([
          Product(
            pseudoId: 'p1',
            productName: 'Apple',
            categories: [
              Category(categoryName: 'Fruit'),
              Category(categoryName: 'Fresh'),
            ],
          ),
        ]),
        Logger(),
      ).single;
      expect(
        p.categories.map((c) => c.categoryName).where((n) => n.isNotEmpty),
        ['Fruit', 'Fresh'],
      );
    });

    test('ProductCsv_header_labelsTheColumnBelowIt', () {
      final lines = csvFromProducts([
        Product(pseudoId: 'p1', useWarehouse: true),
      ]).split('\r\n');
      final header = lines[0].split(',').map((h) => h.trim()).toList();
      final row = lines[1].split(',');
      expect(row[header.indexOf('Use Warehouse')], '"true"');
    });

    test('CategoryCsv_image_importsBackTheSameBytes', () {
      final c = csvToCategories(
        csvFromCategories([
          Category(categoryName: 'Fruit', image: Uint8List.fromList([1, 2, 3])),
        ]),
      ).single;
      expect(c.image, [1, 2, 3]);
    });

    test('GlAccountCsv_noAccountType_exportsWithoutCrash', () {
      final csv = csvFromGlAccounts([
        GlAccount(
          accountCode: '1000',
          accountName: 'Cash',
          accountClass: const AccountClass(description: 'Asset'),
        ),
      ]);
      expect(csvToGlAccounts(csv).single.accountType, isNull);
    });

    test('CompanyCsv_exportedCompany_importsBackUnchanged', () {
      final c = csvToCompanies(
        csvFromCompanies([
          Company(
            pseudoId: 'c1',
            role: Role.supplier,
            name: 'Acme',
            email: 'info@acme.com',
            telephoneNr: '+66 2',
            currency: Currency(currencyId: 'THB'),
            address: Address(city: 'Bangkok', country: 'Thailand'),
          ),
        ]),
      ).single;
      expect(c.telephoneNr, '+66 2');
      expect(c.currency?.currencyId, 'THB');
      expect(c.address?.city, 'Bangkok');
    });
  });
}
