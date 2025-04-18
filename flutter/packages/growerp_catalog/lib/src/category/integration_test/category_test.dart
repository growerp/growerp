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
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

class CategoryTest {
  static Future<void> selectCategories(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbCatalog', 'CategoryList', '2');
  }

  static Future<void> addCategories(
      WidgetTester tester, List<Category> categories,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.categories.isEmpty) {
      // not yet created
      await enterCategoryData(tester, categories);
      await PersistFunctions.persistTest(test.copyWith(categories: categories));
    }
    if (check) {
      await PersistFunctions.persistTest(test.copyWith(
          categories: await checkCategoryDetail(tester, categories)));
    }
  }

  static Future<void> enterCategoryData(
      WidgetTester tester, List<Category> categories) async {
    for (Category category in categories) {
      if (category.categoryId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: category.categoryId);
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            category.categoryId);
      }
      await CommonTest.checkWidgetKey(tester, 'CategoryDialog');
      await CommonTest.tapByKey(
          tester, 'name'); // required because keyboard come up
      await CommonTest.enterText(tester, 'name', category.categoryName);
      await CommonTest.drag(tester);
      await CommonTest.enterText(tester, 'description', category.description);
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Category>> checkCategoryDetail(
      WidgetTester tester, List<Category> categories) async {
    List<Category> newCategories = [];
    for (Category category in categories) {
      // list
      for (final (index, _) in categories.indexed) {
        if (CommonTest.getTextField('id$index') == category.pseudoId) {
          expect(CommonTest.getTextField('name$index'),
              equals(category.categoryName));
          expect(CommonTest.getTextField('products$index'), equals('0'));
        }
      }
      await CommonTest.doNewSearch(tester,
          searchString: category.categoryName, seconds: CommonTest.waitTime);
      // detail
      await CommonTest.tapByKey(tester, 'name0');
      expect(find.byKey(const Key('CategoryDialog')), findsOneWidget);
      expect(
          CommonTest.getTextFormField('name'), equals(category.categoryName));
      expect(CommonTest.getTextFormField('description'),
          equals(category.description));
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      newCategories.add(category.copyWith(categoryId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    return newCategories;
  }

  static Future<void> deleteLastCategory(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.categories.length;
    expect(find.byKey(const Key('categoryItem')),
        findsNWidgets(count)); // initial admin
    await CommonTest.tapByKey(tester, 'delete${count - 1}',
        seconds: CommonTest.waitTime);
    // replacement for refresh...
    expect(find.byKey(const Key('categoryItem')), findsNWidgets(count - 1));
    await PersistFunctions.persistTest(test.copyWith(
        categories: test.categories.sublist(0, test.categories.length - 1)));
  }

  static Future<void> updateCategories(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.categories[0].categoryName != categories[0].categoryName) return;
    List<Category> updCategories = [];
    for (Category category in test.categories) {
      updCategories.add(category.copyWith(
        categoryName: '${category.categoryName}u',
        description: '${category.description}u',
      ));
    }
    await enterCategoryData(tester, updCategories);
    await checkCategoryDetail(tester, updCategories);
    await PersistFunctions.persistTest(
        test.copyWith(categories: updCategories));
  }
}
