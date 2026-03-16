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
import 'package:dio/dio.dart';

class WebsiteTest {
  // used in the admin app
  static Future<void> selectWebsite(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'tapCompany', 'WebsiteDialog', '1');
  }

  static Future<void> updateWeburl(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'urlInput', 'testingUrl');
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(
      tester,
      'modifyWebsiteInfo',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    expect(CommonTest.getTextFormField('urlInput'), equals('testingurl'));
  }

  static Future<void> updateFollowUs(WidgetTester tester) async {
    await CommonTest.dragUntil(tester, key: 'substackUrl');
    await CommonTest.enterText(
      tester,
      'substackUrl',
      'https://test.substack.com',
    );
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(
      tester,
      'modifyWebsiteInfo',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    expect(
      CommonTest.getTextFormField('substackUrl'),
      equals('https://test.substack.com'),
    );
  }

  static Future<void> updateTitle(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'title', 'Test Company');
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'modifyWebsiteInfo', seconds: 2);
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

  /// Verifies that the content updated in [updateTextSection] is also served by
  /// the public store website. This specifically tests the fix for the bug where
  /// [WikiPage.publishedVersionName] was not updated after a content save, causing
  /// the public website to keep serving the original content version.
  ///
  /// Calls /content/{path} which goes through get#PublishedWikiPageText —
  /// the Moqui service that uses publishedVersionName to look up content.
  /// (The PopRestStore store.xml is mounted at the webroot with no-sub-path="true",
  /// so the content screen is at /content/... not /store/content/...)
  ///
  /// [restClient] must be the authenticated client already used by the test.
  static Future<void> checkTextSectionPubliclyUpdated(
    WidgetTester tester,
    RestClient restClient, {
    String expectedText = 'TestingtextNew',
  }) async {
    // Use the admin API to get the website, which gives us:
    //  • the content path (wikiPageId) for the updated page
    //  • the configured hostName used for public store URL resolution
    // get#Website reads directly from DbResourceFile so it always returns the
    // latest content regardless of publishedVersionName.
    final Website website = await restClient.getWebsite();

    // The getWebsite() response uses text:'x' as a marker for pages that have
    // text content — the full text is not returned in the list. Match by title,
    // which is derived from the leading markdown heading
    // (e.g. "# TestingtextNew" → title "TestingtextNew").
    final Content updatedContent = website.websiteContent.firstWhere(
      (c) => c.title == expectedText,
      orElse: () => throw Exception(
        'Expected content with title "$expectedText" not found in '
        'websiteContent list (available: '
        '${website.websiteContent.map((c) => c.title).join(', ')})',
      ),
    );

    // The stored hostName is e.g. "testingurl.localhost:8080".
    // Moqui's StoreServices.get#StoreInfo resolves the ProductStore by matching
    // the request Host header against the stored PsstHostname setting value.
    // It uses getHostName(false) — which strips the port — and then appends
    // :8080 when the hostname contains 'localhost'. So passing the full stored
    // hostName as the Host header produces the correct match.
    final String storeHost = website.hostName;
    if (storeHost.isEmpty) {
      throw Exception(
        'website.hostName is empty — cannot construct public URL',
      );
    }

    // Derive the correct backend address using buildDioClient — this handles
    // Android emulator translation (localhost → 10.0.2.2) and any
    // --dart-define=BACKEND_PORT override automatically.
    final Dio configuredDio = await buildDioClient();
    final String baseUrl = configuredDio.options.baseUrl;

    // Plain (unauthenticated) Dio — simulates a public browser request.
    final dio = Dio(
      BaseOptions(baseUrl: baseUrl, responseType: ResponseType.plain),
    );

    // GET the public content URL.
    // The route /content/{path} calls get#PublishedWikiPageText which
    // reads WikiPage.publishedVersionName. Before the backend fix this always
    // served the original '01' version; after the fix it serves the latest.
    final response = await dio.get(
      '/content/${updatedContent.path}',
      options: Options(
        headers: {'Host': storeHost},
        validateStatus: (status) => status != null,
      ),
    );

    final body = response.data as String;
    expect(
      body.contains(expectedText),
      isTrue,
      reason:
          'Public website at /content/${updatedContent.path} '
          '(Host: $storeHost) should contain "$expectedText" after update, '
          'got HTTP ${response.statusCode}: '
          '${body.length > 300 ? '${body.substring(0, 300)}…' : body}',
    );
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
    await CommonTest.tapByKey(
      tester,
      "testingImage",
      seconds: CommonTest.waitTime,
    );
    await CommonTest.enterText(tester, 'imageName', 'newTestingImage');
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await CommonTest.drag(tester);
    expect(
      tester.any(find.byKey(const Key('testingImage'))),
      equals(false),
      reason: 'testingImage should not be found!',
    );
    expect(
      tester.any(find.byKey(const Key('newTestingImage'))),
      equals(true),
      reason: 'newTestingImage not found!?',
    );
    // Delete newTestingImage via the chip's delete icon (the only delete path
    // now that the remove button has been removed from the content dialog).
    await CommonTest.tapByKey(tester, 'deleteImageChip');
    await CommonTest.tapByKey(tester, 'continue', seconds: CommonTest.waitTime);
    int deleteNewRetries = 0;
    while (tester.any(find.byKey(const Key('newTestingImage'))) &&
        deleteNewRetries++ < 20) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.drag(tester);
    expect(
      tester.any(find.byKey(const Key('newTestingImage'))),
      equals(false),
      reason: 'newTestingImage deleted?',
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
    await CommonTest.drag(tester, seconds: CommonTest.waitTime);
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
    await CommonTest.drag(tester, seconds: CommonTest.waitTime);
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
