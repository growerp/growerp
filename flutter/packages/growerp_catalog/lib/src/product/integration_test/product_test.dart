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
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class ProductTest {
  static Future<void> selectProducts(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/products', 'ProductList');
  }

  static Future<void> addProducts(
    WidgetTester tester,
    List<Product> products, {
    bool check = true,
    String classificationId = "AppAdmin",
  }) async {
    await PersistFunctions.persistTest(SaveTest(products: products));
    await enterProductData(tester, classificationId: classificationId);
    await checkProduct(tester, classificationId: classificationId);
  }

  static Future<void> enterProductData(
    WidgetTester tester, {
    String classificationId = "AppAdmin",
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    List<Product> products = test.products;
    List<Product> newProducts = [];
    for (Product product in products) {
      if (product.pseudoId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: product.pseudoId);
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          product.pseudoId,
        );
      }
      // get formBuilder internal formState
      final formState = tester.state<FormBuilderState>(
        find.byType(FormBuilder),
      );
      formState.save(); // save into the formbuilder internal value fields

      await CommonTest.checkWidgetKey(tester, 'ProductDialog');
      await CommonTest.enterDropDown(
        tester,
        'productTypeDropDown',
        product.productTypeId!,
      );
      await CommonTest.enterText(tester, 'name', product.productName!);
      await CommonTest.drag(tester);
      await CommonTest.enterText(tester, 'description', product.description!);
      await CommonTest.enterText(tester, 'price', product.price.toString());
      await CommonTest.enterText(
        tester,
        'listPrice',
        product.listPrice.toString(),
      );
      if (classificationId == 'AppAdmin') {
        await CommonTest.dragUntil(tester, key: 'addCategories');
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
        // Uom and amount
        await CommonTest.enterDropDown(
          tester,
          'uomTypeDropDown',
          product.amountUom!.typeDescription,
        );
        await CommonTest.enterDropDown(
          tester,
          'uomDropDown',
          product.amountUom!.description,
        );
        await CommonTest.enterText(tester, 'amount', product.amount.toString());
      }
      if (product.productTypeId != 'Service') {
        await CommonTest.dragUntil(tester, key: 'useWarehouse');
        if ((product.useWarehouse == true &&
                formState.value['useWarehouse'] == false) ||
            (product.useWarehouse == false &&
                formState.value['useWarehouse'] == true)) {
          await CommonTest.tapByKey(tester, 'useWarehouse');
        }
      }
      await CommonTest.dragUntil(tester, key: 'update');
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
      // get pseudoId from list always at the top
      if (product.pseudoId.isEmpty) {
        newProducts.add(
          product.copyWith(pseudoId: CommonTest.getTextField('id0')),
        );
      } else {
        newProducts.add(product);
      }
    }
    await PersistFunctions.persistTest(SaveTest(products: newProducts));
  }

  static Future<void> checkProduct(
    WidgetTester tester, {
    String classificationId = 'AppAdmin',
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    List<Product> products = test.products;
    List<Product> newProducts = [];
    for (Product product in products) {
      await CommonTest.doNewSearch(tester, searchString: product.pseudoId);
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      // get formBuilder internal formState
      final formState = tester.state<FormBuilderState>(
        find.byType(FormBuilder),
      );
      formState.save(); // save into the formbuilder internal value fields
      var errors = CommonTest.checkFormBuilderTextfields(formState, {
        'name': product.productName,
        'description': product.description,
        'price': product.price.currency(currencyId: ''),
        'listPrice': product.listPrice.currency(currencyId: ''),
      });
      expect(errors.isEmpty, isTrue, reason: errors.toString());
      expect(find.byKey(const Key('ProductDialog')), findsOneWidget);
      if (classificationId == 'AppAdmin') {
        for (Category category in product.categories) {
          expect(find.byKey(Key(category.categoryName)), findsOneWidget);
        }
        var errors = CommonTest.checkFormBuilderTextfields(formState, {
          'productType': product.productTypeId,
          'amount': product.amount.toString(),
        });
        expect(errors.isEmpty, isTrue, reason: errors.toString());
        if (product.productTypeId != 'Service') {
          expect(formState.value['useWarehouse'], product.useWarehouse);
        }
        expect(
          (formState.value['uomType'] as Uom).typeDescription,
          product.amountUom!.typeDescription,
        );
        expect(
          (formState.value['uom'] as Uom).description,
          product.amountUom!.description,
        );
      }
      newProducts.add(product.copyWith(pseudoId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await PersistFunctions.persistTest(SaveTest(products: newProducts));
  }

  static Future<void> deleteLastProduct(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.products.length;
    await CommonTest.gotoMainMenu(tester);
    await ProductTest.selectProducts(tester);
    expect(find.byKey(const Key('productItem')), findsNWidgets(count));
    await CommonTest.tapByKey(
      tester,
      'delete${count - 2}',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.gotoMainMenu(tester);
    await ProductTest.selectProducts(tester);
    expect(find.byKey(const Key('productItem')), findsNWidgets(count - 1));
    await PersistFunctions.persistTest(
      test.copyWith(
        products: test.products.sublist(0, test.products.length - 1),
      ),
    );
  }

  static Future<void> updateProducts(
    WidgetTester tester,
    List<Product> products, {
    bool check = true,
    String classificationId = "AppAdmin",
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    List<Product> oldProducts = test.products;
    List<Product> newProducts = List.of(products);
    // copy pseudoId to new products
    for (int x = 0; x < newProducts.length; x++) {
      newProducts[x] = newProducts[x].copyWith(
        pseudoId: oldProducts[x].pseudoId,
      );
    }
    await PersistFunctions.persistTest(test.copyWith(products: newProducts));
    await enterProductData(tester, classificationId: classificationId);
    await checkProduct(tester, classificationId: classificationId);
  }
}
