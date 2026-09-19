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

class EmailSequenceTest {
  static Future<void> selectEmailSequences(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/emailSequences',
      'EmailSequenceList',
      null,
    );
  }

  static Future<void> addEmailSequences(
    WidgetTester tester,
    List<EmailSequence> sequences,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
      test.copyWith(emailSequences: sequences),
    );
    await enterEmailSequenceData(tester);
  }

  static Future<void> updateEmailSequences(
    WidgetTester tester,
    List<EmailSequence> newSequences,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    List<EmailSequence> updated = [];
    for (int x = 0; x < newSequences.length; x++) {
      updated.add(
        newSequences[x].copyWith(
          emailSequenceId: old.emailSequences[x].emailSequenceId,
          pseudoId: old.emailSequences[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(
      old.copyWith(emailSequences: updated),
    );
    await enterEmailSequenceData(tester);
  }

  static Future<void> deleteEmailSequences(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.emailSequences.length;
    expect(
      find.byKey(Key('id${count - 1}'), skipOffstage: false),
      findsOneWidget,
    );
    await CommonTest.tapByKey(tester, 'delete0', seconds: CommonTest.waitTime);
    await CommonTest.tapByKey(tester, 'continue', seconds: CommonTest.waitTime);
    expect(
      find.byKey(Key('id${count - 1}'), skipOffstage: false),
      findsNothing,
    );
    await PersistFunctions.persistTest(
      test.copyWith(emailSequences: test.emailSequences.sublist(1, count)),
    );
  }

  static Future<void> doEmailSequenceSearch(
    WidgetTester tester, {
    required String searchString,
  }) async {
    await CommonTest.doNewSearch(tester, searchString: searchString);
  }

  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pump(const Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> enterEmailSequenceData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<EmailSequence> newSequences = [];

    for (EmailSequence sequence in test.emailSequences) {
      if (sequence.pseudoId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await doEmailSequenceSearch(tester, searchString: sequence.pseudoId);
        expect(
          CommonTest.getTextField('topHeader').contains(sequence.pseudoId),
          true,
        );
      }

      expect(find.byKey(const Key('EmailSequenceDialog')), findsOneWidget);

      await CommonTest.enterText(
        tester,
        'sequenceName',
        sequence.sequenceName,
      );
      if (sequence.steps.isNotEmpty) {
        final step = sequence.steps.first;
        await CommonTest.enterText(tester, 'stepSubject0', step.subject);
        await CommonTest.enterText(tester, 'stepBody0', step.bodyHtml);
      }

      await CommonTest.tapByKey(
        tester,
        'update',
        seconds: CommonTest.waitTime,
      );

      // Get the allocated pseudoId for newly created sequences
      if (sequence.pseudoId.isEmpty) {
        await CommonTest.tapByKey(
          tester,
          'sequenceName0',
          seconds: CommonTest.waitTime,
        );
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        sequence = sequence.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newSequences.add(sequence);
    }

    await clearSearch(tester);
    await PersistFunctions.persistTest(
      test.copyWith(emailSequences: newSequences),
    );
  }

  static Future<void> checkEmailSequences(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (EmailSequence sequence in test.emailSequences) {
      await doEmailSequenceSearch(tester, searchString: sequence.pseudoId);

      expect(find.byKey(const Key('EmailSequenceDialog')), findsOneWidget);
      expect(
        CommonTest.getTextFormField('sequenceName'),
        equals(sequence.sequenceName),
      );
      if (sequence.steps.isNotEmpty) {
        expect(
          CommonTest.getTextFormField('stepSubject0'),
          equals(sequence.steps.first.subject),
        );
      }

      await CommonTest.tapByKey(tester, 'cancel');
    }
    await clearSearch(tester);
  }

  /// Open the members dialog for the sequence at [index] in the current list.
  static Future<void> openMembers(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(
      tester,
      'members$index',
      seconds: CommonTest.waitTime,
    );
    expect(find.byKey(const Key('EmailSequenceMembersDialog')), findsOneWidget);
  }

  /// Add a member from the (already open) members dialog and verify it shows
  /// up as row 0 with an ACTIVE status.
  static Future<void> addMember(
    WidgetTester tester, {
    required String email,
    String firstName = '',
  }) async {
    await CommonTest.tapByKey(
      tester,
      'addNewMember',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.enterText(tester, 'memberEmail', email);
    await CommonTest.enterText(tester, 'memberFirstName', firstName);
    await CommonTest.tapByKey(
      tester,
      'addMember',
      seconds: CommonTest.waitTime,
    );
    expect(CommonTest.getTextField('email0'), equals(email));
    expect(CommonTest.getTextField('status0'), equals('ACTIVE'));
  }

  /// Search the (already open) member list and let the debounced backend
  /// filter apply.
  static Future<void> searchMembers(
    WidgetTester tester, {
    required String searchString,
  }) async {
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pump(const Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// Unsubscribe the member at [index] and verify its status flips, while the
  /// row stays visible.
  static Future<void> unsubscribeMember(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(
      tester,
      'unsubscribe$index',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(
      tester,
      'continue',
      seconds: CommonTest.waitTime,
    );
    expect(CommonTest.getTextField('status$index'), equals('UNSUBSCRIBED'));
  }

  /// Close the (already open) members dialog.
  static Future<void> closeMembers(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'cancel', seconds: CommonTest.waitTime);
  }
}
