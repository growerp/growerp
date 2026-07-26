/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

class CategoryTest {
  static Future<void> selectCategories(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/categories', 'CategoryList');
  }

  static Future<void> addCategories(
    WidgetTester tester,
    List<Category> categories, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.categories.isEmpty) {
      // not yet created
      await enterCategoryData(tester, categories);
      await PersistFunctions.persistTest(test.copyWith(categories: categories));
    }
    if (check) {
      await PersistFunctions.persistTest(
        test.copyWith(
          categories: await checkCategoryDetail(tester, categories),
        ),
      );
    }
  }

  static Future<void> enterCategoryData(
    WidgetTester tester,
    List<Category> categories,
  ) async {
    for (Category category in categories) {
      if (category.categoryId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: category.categoryId);
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          category.categoryId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'CategoryDialog');
      await CommonTest.tapByKey(
        tester,
        'name',
      ); // required because keyboard come up
      await CommonTest.enterText(tester, 'name', category.categoryName);
      await CommonTest.enterText(tester, 'description', category.description);
      await CommonTest.dragUntil(tester, key: 'update');
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
    // Clear search filter to restore full list for subsequent operations
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<List<Category>> checkCategoryDetail(
    WidgetTester tester,
    List<Category> categories,
  ) async {
    List<Category> newCategories = [];
    for (Category category in categories) {
      await CommonTest.doNewSearch(
        tester,
        searchString: category.categoryName,
        seconds: CommonTest.waitTime,
      );
      // After search, verify the item is found (at index 0 since search filters)
      expect(CommonTest.getTextField('name0'), equals(category.categoryName));
      // The products text format varies based on screen size (mobile: "0 products", desktop: "0")
      expect(
        CommonTest.getTextField('products0'),
        anyOf(equals('0'), equals('0 products')),
      );
      // detail
      expect(find.byKey(const Key('CategoryDialog')), findsOneWidget);
      expect(
        CommonTest.getTextFormField('name'),
        equals(category.categoryName),
      );
      expect(
        CommonTest.getTextFormField('description'),
        equals(category.description),
      );
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      newCategories.add(category.copyWith(categoryId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    // Clear search filter after checking all categories
    await CommonTest.enterText(tester, 'searchField', '');
    return newCategories;
  }

  static Future<void> deleteLastCategory(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.categories.length;
    // Clear any active search filter to show all categories
    await CommonTest.enterText(tester, 'searchField', '');
    expect(
      find.byKey(const Key('categoryItem')),
      findsNWidgets(count),
    ); // initial admin
    await CommonTest.tapByKey(
      tester,
      'delete${count - 3}', // other keys are covered by fab
      seconds: CommonTest.waitTime,
    );
    // replacement for refresh...
    expect(find.byKey(const Key('categoryItem')), findsNWidgets(count - 1));
    await PersistFunctions.persistTest(
      test.copyWith(
        categories: test.categories.sublist(0, test.categories.length - 1),
      ),
    );
  }

  static Future<void> updateCategories(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.categories[0].categoryName != categories[0].categoryName) return;
    List<Category> updCategories = [];
    for (Category category in test.categories) {
      updCategories.add(
        category.copyWith(
          categoryName: '${category.categoryName}u',
          description: '${category.description}u',
        ),
      );
    }
    await enterCategoryData(tester, updCategories);
    await checkCategoryDetail(tester, updCategories);
    // Final search clear before returning to list view
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await PersistFunctions.persistTest(
      test.copyWith(categories: updCategories),
    );
  }
}
