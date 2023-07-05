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

// ignore_for_file: depend_on_referenced_packages
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';

class ProductTest {
  static Future<void> selectProducts(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbCatalog', 'ProductListForm', '1');
  }

  static Future<void> addProducts(WidgetTester tester, List<Product> products,
      {bool check = true, String classificationId = "AppAdmin"}) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    // test = test.copyWith(products: []); // ======== remove , just for test
    if (test.products.isEmpty) {
      // not yet created
      test = test.copyWith(products: products);
      await enterProductData(tester, products,
          classificationId: classificationId);
      await PersistFunctions.persistTest(test.copyWith(products: products));
    }
    if (check) {
      await PersistFunctions.persistTest(test.copyWith(
          products: await checkProduct(tester, products,
              classificationId: classificationId)));
    }
  }

  static Future<void> enterProductData(
      WidgetTester tester, List<Product> products,
      {String classificationId = "AppAdmin"}) async {
    for (Product product in products) {
      if (product.productId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: product.productId);
        await CommonTest.tapByKey(tester, 'name0');
        expect(
            CommonTest.getTextField('header').split('#')[1], product.productId);
      }
      await CommonTest.checkWidgetKey(tester, 'ProductDialog');
      await CommonTest.enterText(tester, 'name', product.productName!);
      await CommonTest.enterText(tester, 'description', product.description!);
      await CommonTest.drag(tester);
      await CommonTest.enterText(tester, 'price', product.price.toString());
      await CommonTest.enterText(
          tester, 'listPrice', product.listPrice.toString());
      if (classificationId == 'AppAdmin') {
        await CommonTest.drag(tester);
        // remove existing categories
        while (tester.any(find.byKey(const Key("deleteChip")))) {
          await CommonTest.tapByKey(tester, "deleteChip");
        }
        await CommonTest.tapByKey(tester, "addCategories");
        for (Category category in product.categories) {
          await CommonTest.tapByText(tester, category.categoryName);
        }
        await CommonTest.tapByKey(tester, 'ok');
        await CommonTest.dragUntil(tester, key: 'productTypeDropDown');
        await CommonTest.enterDropDown(
            tester, 'productTypeDropDown', product.productTypeId!);
        if (product.productTypeId != 'Service') {
          if (product.useWarehouse == true) {
            await CommonTest.tapByKey(tester, 'useWarehouse');
          }
        }
      }
      // needed when service is removed
      await CommonTest.dragUntil(tester, key: 'update');
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'dismiss');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Product>> checkProduct(
      WidgetTester tester, List<Product> products,
      {String classificationId = 'AppAdmin'}) async {
    List<Product> newProducts = [];
    for (Product product in products) {
      await CommonTest.doSearch(tester, searchString: product.productName!);
      // list
      expect(CommonTest.getTextField('name0'), equals(product.productName));
      expect(
          CommonTest.getTextField('price0'), equals(product.price.toString()));
      if (classificationId == 'AppAdmin') {
        if (product.categories.length == 1) {
          expect(CommonTest.getTextField('categoryName0'),
              equals(product.categories[0].categoryName));
        } else {
          expect(CommonTest.getTextField('categoryName0'),
              equals(product.categories.length.toString()));
        }
      }
      if (!CommonTest.isPhone()) {
        expect(CommonTest.getTextField('description0'),
            equals(product.description));
      }
      // detail screen
      await CommonTest.tapByKey(tester, 'name0');
      var id = CommonTest.getTextField('header').split('#')[1];
      expect(find.byKey(const Key('ProductDialog')), findsOneWidget);
      expect(CommonTest.getTextFormField('name'), product.productName);
      expect(CommonTest.getTextFormField('description'), product.description);
      expect(CommonTest.getTextFormField('price'), product.price.toString());
      expect(CommonTest.getTextFormField('listPrice'),
          product.listPrice.toString());
      if (classificationId == 'AppAdmin') {
        for (Category category in product.categories) {
          expect(find.byKey(Key(category.categoryName)), findsOneWidget);
        }
        // not sure how to test checked list
//      await CommonTest.tapByKey(tester, 'addCategories');
//      for (Category category in product.categories) {
//        expect(
//            CommonTest.getCheckboxListTile("${category.categoryName!}["), true);
//      }
//      if (product.productTypeId != 'service') {
//        expect(
//          CommonTest.getCheckboxListTile('useWarehouse'), product.useWarehouse);
//      }
        expect(CommonTest.getDropdown('productTypeDropDown'),
            product.productTypeId);
      }
      newProducts.add(product.copyWith(productId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return newProducts;
  }

  static Future<void> deleteLastProduct(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.products.length;
    await CommonTest.gotoMainMenu(tester);
    await ProductTest.selectProducts(tester);
    expect(find.byKey(const Key('productItem')), findsNWidgets(count));
    await CommonTest.tapByKey(tester, 'delete${count - 1}', seconds: 5);
    await CommonTest.gotoMainMenu(tester);
    await ProductTest.selectProducts(tester);
    expect(find.byKey(const Key('productItem')), findsNWidgets(count - 1));
    await PersistFunctions.persistTest(test.copyWith(
        products: test.products.sublist(0, test.products.length - 1)));
  }

  static Future<void> updateProducts(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.products[0].productName == products[0].productName) {
      List<Product> updProducts = [];
      for (Product product in test.products) {
        updProducts.add(product.copyWith(
          productName: '${product.productName!}u',
          description: '${product.description!}u',
          categories: [product.categories[0]],
          productTypeId: productTypes[0],
          price: product.price! + Decimal.parse('0.10'),
          listPrice: product.listPrice! + Decimal.parse('0.99'),
        ));
      }
      await enterProductData(tester, updProducts);
      await PersistFunctions.persistTest(test.copyWith(products: updProducts));
    }
    test = await PersistFunctions.getTest();
    await checkProduct(tester, test.products);
  }
}
