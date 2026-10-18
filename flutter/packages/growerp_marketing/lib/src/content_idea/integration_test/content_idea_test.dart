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

/// Ideas strip on the Content screen: add (text + URL), update, collapse,
/// delete. Writing an article needs an AI key, so it is not part of this test.
/// Titles stay under 30 characters, the chip label length.
class ContentIdeaTest {
  static Future<void> selectContent(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/masterContent',
      'MasterContentList',
      null,
    );
  }

  static Future<void> addContentIdea(
    WidgetTester tester, {
    required String title,
    String text = '',
    String url = '',
  }) async {
    await CommonTest.tapByKey(tester, 'addNewContentIdea');
    expect(find.byKey(const Key('ContentIdeaDialognull')), findsOneWidget);
    await CommonTest.enterText(tester, 'ideaTitle', title);
    if (text.isNotEmpty) await CommonTest.enterText(tester, 'ideaRawText', text);
    if (url.isNotEmpty) await CommonTest.enterText(tester, 'ideaSourceUrl', url);
    await CommonTest.dragUntil(
      tester,
      key: 'ideaSave',
      listViewName: 'contentIdeaDialogListView',
    );
    await CommonTest.tapByKey(tester, 'ideaSave',
        seconds: CommonTest.waitTime);
  }

  static void checkIdeas(List<String> titles) {
    expect(CommonTest.getTextField('ideasCount'),
        equals('Ideas (${titles.length})'));
    for (final (index, title) in titles.indexed) {
      expect(CommonTest.getTextField('ideaTitle$index'), equals(title));
    }
  }

  static Future<void> updateContentIdea(
    WidgetTester tester, {
    required int index,
    required String newTitle,
  }) async {
    await CommonTest.tapByKey(tester, 'idea$index',
        seconds: CommonTest.waitTime);
    await CommonTest.enterText(tester, 'ideaTitle', newTitle);
    await CommonTest.dragUntil(
      tester,
      key: 'ideaSave',
      listViewName: 'contentIdeaDialogListView',
    );
    await CommonTest.tapByKey(tester, 'ideaSave',
        seconds: CommonTest.waitTime);
  }

  static Future<void> toggleIdeas(WidgetTester tester,
      {required bool expectCollapsed}) async {
    await CommonTest.tapByKey(tester, 'ideasToggle');
    expect(find.byKey(const Key('addNewContentIdea')),
        expectCollapsed ? findsNothing : findsOneWidget);
  }

  static Future<void> deleteContentIdea(WidgetTester tester,
      {required int index}) async {
    await CommonTest.tapByKey(tester, 'idea$index',
        seconds: CommonTest.waitTime);
    await CommonTest.dragUntil(
      tester,
      key: 'ideaDiscard',
      listViewName: 'contentIdeaDialogListView',
    );
    await CommonTest.tapByKey(tester, 'ideaDiscard',
        seconds: CommonTest.waitTime);
  }
}
