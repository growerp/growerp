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
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

class WebsiteTest {
  // used in the admin app
  static Future<void> selectWebsite(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'tapCompany', 'WebsiteDialog', '1');
  }

  static Future<void> updateHost(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'urlInput', 'testingUrl');
    await CommonTest.tapByKey(
      tester,
      'updateHost',
      seconds: CommonTest.waitTime,
    );
    expect(CommonTest.getTextFormField('urlInput'), equals('testingurl'));
    expect(CommonTest.getTextField("url"), startsWith('testingurl.'));
  }

  static Future<void> updateWeburl(WidgetTester tester) async {
    // Comprehensive test for changing the website URL with multiple scenarios

    // Test URL changes with different scenarios
    await _testUrlChange(tester, 'mycompany', 'Basic URL change');
    await _testUrlChange(tester, 'TestCompany', 'Uppercase URL change');
    await _testUrlChange(tester, 'test-site', 'Hyphenated URL change');
  }

  // Helper function to test URL changes
  static Future<void> _testUrlChange(
    WidgetTester tester,
    String url,
    String description,
  ) async {
    // Enter the new URL
    await CommonTest.enterText(tester, 'urlInput', url);
    await CommonTest.tapByKey(
      tester,
      'updateHost',
      seconds: CommonTest.waitTime,
    );

    // Get the expected result (URLs are typically converted to lowercase)
    String expectedUrl = url.toLowerCase();

    // Verify the URL was updated
    String actualUrlInput = CommonTest.getTextFormField('urlInput');
    String actualDisplayUrl = CommonTest.getTextField("url");

    expect(
      actualUrlInput,
      equals(expectedUrl),
      reason:
          '$description: URL input should be updated to $expectedUrl, but got $actualUrlInput',
    );

    expect(
      actualDisplayUrl,
      startsWith('$expectedUrl.'),
      reason:
          '$description: Displayed URL should start with $expectedUrl., but got $actualDisplayUrl',
    );
  }

  // Standalone URL test method that can be called independently
  static Future<void> runUrlChangeTest(WidgetTester tester) async {
    // This method provides the same functionality as the standalone test
    // but can be integrated into other test workflows

    await _testUrlChange(tester, 'mycompany', 'Basic URL change');
    await _testUrlChange(tester, 'TestCompany', 'Uppercase URL change');
    await _testUrlChange(tester, 'test-site', 'Hyphenated URL change');
    await _testUrlChange(
      tester,
      'new_company123',
      'URL with numbers and underscore',
    );
  }

  static Future<void> updateTitle(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'title', 'Test Company');
    await CommonTest.tapByKey(tester, 'updateTitle', seconds: 2);
    expect(CommonTest.getTextFormField('title'), equals('Test Company'));
  }

  static Future<void> updateTextSection(WidgetTester tester) async {
    while (tester.any(find.byKey(const Key("deleteTextChip")))) {
      await CommonTest.tapByKey(tester, "deleteTextChip");
      await CommonTest.tapByKey(
        tester,
        "continue",
        seconds: CommonTest.waitTime,
      );
    }
    await CommonTest.tapByKey(tester, 'addText');
    await CommonTest.enterText(tester, 'mdInput', '# Testingtext');
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    expect(CommonTest.getTextField("Testingtext"), equals('Testingtext'));
    await CommonTest.tapByKey(
      tester,
      'Testingtext',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.enterText(tester, 'mdInput', '# TestingtextNew');
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    expect(CommonTest.getTextField("TestingtextNew"), equals('TestingtextNew'));
  }

  static Future<void> updateImages(WidgetTester tester) async {
    while (tester.any(find.byKey(const Key("deleteImageChip")))) {
      await CommonTest.tapByKey(tester, "deleteImageChip");
      await CommonTest.tapByKey(
        tester,
        "continue",
        seconds: CommonTest.waitTime,
      );
      await CommonTest.waitForSnackbarToGo(tester);
    }
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'addImage');
    await CommonTest.enterText(tester, 'imageName', 'testingImage');
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    expect(
      tester.any(find.byKey(const Key('testingImage'))),
      equals(true),
      reason: 'testingImage found?',
    );
    await CommonTest.tapByKey(tester, "testingImage");
    await CommonTest.enterText(tester, 'imageName', 'newTestingImage');
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    expect(
      tester.any(find.byKey(const Key('testingImage'))),
      equals(false),
      reason: 'testingImage NOT found?',
    );
    expect(
      tester.any(find.byKey(const Key('newTestingImage'))),
      equals(true),
      reason: 'newTestingImage found?',
    );
  }

  static Future<void> updateHomePageCategories(
    WidgetTester tester,
    String categoryName,
    List<Product> products,
  ) async {
    // delete
    while (tester.any(find.byKey(const Key("deleteProductChip")))) {
      await CommonTest.tapByKey(tester, "deleteProductChip");
    }
    await CommonTest.dragUntil(tester, key: "addProduct$categoryName");
    await CommonTest.enterDropDownSearch(
      tester,
      "addProduct$categoryName",
      products[0].productName!,
    );
    await CommonTest.tapByText(tester, "ok");
    await CommonTest.drag(tester);
    expect(
      tester.any(find.byKey(Key(products[0].productName!))),
      equals(true),
      reason: 'product 0 found?',
    );
    await CommonTest.tapByKey(tester, "deleteProductChip");
    await CommonTest.drag(tester);
    expect(
      tester.any(find.byKey(Key(products[0].productName!))),
      equals(false),
      reason: 'product 0 NOT found?',
    );
  }

  static Future<void> updateShopCategories(WidgetTester tester) async {
    await CommonTest.drag(tester);
    while (tester.any(find.byKey(const Key("deleteCategoryChip")))) {
      await CommonTest.tapByKey(
        tester,
        "deleteCategoryChip",
        seconds: CommonTest.waitTime,
      );
      await CommonTest.tapByKey(tester, "continue", seconds: 2);
      await CommonTest.drag(tester);
    }
    await CommonTest.drag(tester);
    await CommonTest.enterDropDownSearch(
      tester,
      "addShopCategory",
      categories[0].categoryName,
      check: true,
    );
    await CommonTest.tapByText(tester, "ok");
    await CommonTest.drag(tester);
    expect(
      find.byKey(Key(categories[0].categoryName)),
      findsOneWidget,
      reason: 'category 0 should be present?',
    );
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(
      tester,
      'deleteCategoryChip',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(tester, "continue", seconds: 2);
    await CommonTest.drag(tester);
    expect(
      find.byKey(Key(categories[0].categoryName)),
      findsNothing,
      reason: 'category 0 should not be found?',
    );
  }
}
