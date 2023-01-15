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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class WebsiteTest {
  // used in the admin app
  static Future<void> selectWebsite(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'tapCompany', 'WebsiteForm', '4');
  }

  static Future<void> updateWebsite(WidgetTester tester) async {
    await updateHost(tester);
    await updateTitle(tester);
    await updateTextSection(tester);
    await updateImages(tester);
    await updateHomePageCategories(tester);
    await updateShopCategories(tester);
  }

  static Future<void> updateHost(tester) async {
    await CommonTest.enterText(tester, 'urlInput', 'testingUrl');
    await CommonTest.tapByKey(tester, 'updateHost', seconds: 3);
    expect(CommonTest.getTextFormField('urlInput'), equals('testingurl'));
    expect(CommonTest.getTextField("url"), startsWith('testingurl.'));
  }

  static Future<void> updateTitle(tester) async {
    await CommonTest.enterText(tester, 'title', 'Test Company');
    await CommonTest.tapByKey(tester, 'updateTitle', seconds: 2);
    expect(CommonTest.getTextFormField('title'), equals('Test Company'));
  }

  static Future<void> updateTextSection(tester) async {
    while (tester.any(find.byKey(const Key("deleteTextChip")))) {
      await CommonTest.tapByKey(tester, "deleteTextChip");
      await CommonTest.tapByKey(tester, "continue", seconds: 3);
    }
    await CommonTest.tapByKey(tester, 'addText');
    await CommonTest.enterText(tester, 'mdInput', '# Testingtext');
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    expect(CommonTest.getTextField("Testingtext"), equals('Testingtext'));
    await CommonTest.tapByKey(tester, 'Testingtext', seconds: 3);
    await CommonTest.enterText(tester, 'mdInput', '# TestingtextNew');
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    expect(CommonTest.getTextField("TestingtextNew"), equals('TestingtextNew'));
  }

  static Future<void> updateImages(tester) async {
    while (tester.any(find.byKey(const Key("deleteImageChip")))) {
      await CommonTest.tapByKey(tester, "deleteImageChip");
      await CommonTest.tapByKey(tester, "continue", seconds: 3);
    }
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'addImage');
    await CommonTest.enterText(tester, 'imageName', 'testingImage');
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    expect(tester.any(find.byKey(const Key('testingImage'))), equals(true),
        reason: 'testingImage found?');
    await CommonTest.tapByKey(tester, "testingImage");
    await CommonTest.enterText(tester, 'imageName', 'newTestingImage');
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    expect(tester.any(find.byKey(const Key('testingImage'))), equals(false),
        reason: 'testingImage NOT found?');
    expect(tester.any(find.byKey(const Key('newTestingImage'))), equals(true),
        reason: 'newTestingImage found?');
  }

  static Future<void> updateHomePageCategories(tester) async {
    await CommonTest.tapByKey(tester, "Deals");
    await CommonTest.tapByKey(tester, "addProducts");
    await CommonTest.tapByText(tester, products[0].productName!);
    await CommonTest.tapByKey(tester, "ok");
    expect(tester.any(find.byKey(Key(products[0].productName!))), equals(true),
        reason: 'product 0 found?');
    await CommonTest.tapByKey(tester, 'update', seconds: 5);
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, "Deals");
    await CommonTest.tapByKey(tester, "delete${products[0].productName!}");
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, "Deals");
    expect(tester.any(find.byKey(Key(products[0].productName!))), equals(false),
        reason: 'product 0 NOT found?');
    await CommonTest.tapByKey(tester, "cancel");
  }

  static Future<void> updateShopCategories(tester) async {
    await CommonTest.drag(tester);
    if (tester.any(find.byKey(Key("delete${categories[0].categoryName}"))) ==
        true) {
      await CommonTest.tapByKey(tester, 'delete${categories[0].categoryName}',
          seconds: 5);
      await CommonTest.tapByKey(tester, "continue", seconds: 3);
    }
    await CommonTest.drag(tester);
    if (tester.any(find.byKey(Key("delete${categories[1].categoryName}"))) ==
        true) {
      await CommonTest.tapByKey(tester, 'delete${categories[1].categoryName}',
          seconds: 5);
      await CommonTest.tapByKey(tester, "continue", seconds: 3);
    }
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'addShopCategory');
    await CommonTest.tapByText(tester, categories[0].categoryName);
    await CommonTest.tapByKey(tester, 'ok');
    await CommonTest.drag(tester);
    expect(
        tester.any(find.byKey(Key(categories[0].categoryName))), equals(true),
        reason: 'category 0 found?');
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'delete${categories[0].categoryName}',
        seconds: 5);
    await CommonTest.tapByKey(tester, "continue", seconds: 3);
    await CommonTest.drag(tester);
    expect(
        tester.any(find.byKey(Key(categories[0].categoryName))), equals(false),
        reason: 'category 0 NOT found?');
  }
}
