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
import 'package:growerp_models/growerp_models.dart';

class CommunicationTest {
  /// Open the communications of the user with [pseudoId] from a user list,
  /// then add, check, update and delete one, ending back on the user list.
  static Future<void> addUpdateDeleteCommunication(
    WidgetTester tester,
    String pseudoId,
    List<CommunicationEvent> communications,
  ) async {
    await CommonTest.doNewSearch(tester, searchString: pseudoId);
    await CommonTest.dragUntil(
      tester,
      key: 'communications',
      listViewName: 'userDialogListView',
    );
    await CommonTest.tapByKey(
      tester,
      'communications',
      seconds: CommonTest.waitTime,
    );
    expect(find.byKey(const Key('CommunicationListDialog')), findsOneWidget);
    expect(find.byKey(const Key('empty')), findsOneWidget);

    // add
    await CommonTest.tapByKey(tester, 'addNewCommunication');
    await enterCommunicationData(tester, communications[0]);
    expect(CommonTest.getTextField('subject0'), communications[0].subject);

    // check and update
    await CommonTest.tapByKey(tester, 'subject0');
    await checkCommunicationDetail(tester, communications[0]);
    await enterCommunicationData(tester, communications[1]);
    expect(CommonTest.getTextField('subject0'), communications[1].subject);
    await CommonTest.tapByKey(tester, 'subject0');
    await checkCommunicationDetail(tester, communications[1]);

    // delete
    await CommonTest.tapByKey(
      tester,
      'deleteCommunication',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    expect(find.byKey(const Key('empty')), findsOneWidget);

    // close the communications list and the user dialog
    await CommonTest.tapByKey(tester, 'cancel');
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> enterCommunicationData(
    WidgetTester tester,
    CommunicationEvent communication,
  ) async {
    expect(find.byKey(const Key('CommunicationDialog')), findsOneWidget);
    await CommonTest.selectDropDown(
      tester,
      'type',
      '',
      optionKey: 'type_${communication.type!.name}',
    );
    await CommonTest.selectDropDown(
      tester,
      'direction',
      '',
      optionKey: 'direction_${communication.direction!.name}',
    );
    await CommonTest.enterText(tester, 'subject', communication.subject!);
    await CommonTest.enterText(tester, 'body', communication.body ?? '');
    await CommonTest.enterText(tester, 'note', communication.note ?? '');
    await CommonTest.dragUntil(
      tester,
      key: 'updateCommunication',
      listViewName: 'communicationDialogListView',
    );
    await CommonTest.tapByKey(
      tester,
      'updateCommunication',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    expect(find.byKey(const Key('CommunicationDialog')), findsNothing);
  }

  static Future<void> checkCommunicationDetail(
    WidgetTester tester,
    CommunicationEvent communication,
  ) async {
    expect(find.byKey(const Key('CommunicationDialog')), findsOneWidget);
    expect(CommonTest.getTextFormField('subject'), communication.subject);
    expect(CommonTest.getTextFormField('body'), communication.body ?? '');
    expect(CommonTest.getTextFormField('note'), communication.note ?? '');
    expect(
      CommonTest.getDropdown('direction'),
      communication.direction.toString(),
    );
  }
}
