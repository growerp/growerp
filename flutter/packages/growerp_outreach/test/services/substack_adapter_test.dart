/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:growerp_outreach/src/services/adapters/substack_automation_adapter.dart';
import 'package:growerp_outreach/src/services/flutter_mcp_browser_service.dart';
import 'package:growerp_outreach/src/services/snapshot_parser.dart';

class MockFlutterMcpBrowserService extends Mock
    implements FlutterMcpBrowserService {}

class FakeSnapshotElement extends Fake implements SnapshotElement {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSnapshotElement());
  });

  late MockFlutterMcpBrowserService mockBrowser;
  late SubstackAutomationAdapter adapter;

  setUp(() {
    mockBrowser = MockFlutterMcpBrowserService();
    adapter = SubstackAutomationAdapter(browser: mockBrowser);
  });

  /// Stubs browser calls needed by [SubstackAutomationAdapter.initialize].
  void stubInitialize() {
    when(() => mockBrowser.initialize()).thenAnswer((_) async {});
    when(() => mockBrowser.navigate(any())).thenAnswer((_) async {});
    when(() => mockBrowser.wait(any())).thenAnswer((_) async {});
  }

  group('SubstackAutomationAdapter.postNote', () {
    test('posts a note successfully', () async {
      final composeArea = SnapshotElement(
        ref: 'e1',
        role: 'textbox',
        name: 'What is on your mind?',
      );
      final postButton = SnapshotElement(
        ref: 'e2',
        role: 'button',
        name: 'Post',
      );
      final snapshotWithCompose = SnapshotElement(
        ref: 'root',
        role: 'document',
        children: [composeArea],
      );
      final snapshotWithPost = SnapshotElement(
        ref: 'root',
        role: 'document',
        children: [composeArea, postButton],
      );

      stubInitialize();

      var snapshotCallCount = 0;
      when(() => mockBrowser.snapshot()).thenAnswer((_) async {
        snapshotCallCount++;
        return snapshotCallCount == 1 ? snapshotWithCompose : snapshotWithPost;
      });
      when(() => mockBrowser.clickElement(any())).thenAnswer((_) async {});
      when(() => mockBrowser.typeIntoElement(any(), any()))
          .thenAnswer((_) async {});

      await adapter.initialize();

      const noteContent = 'Hello Substack! This is a test note.';
      await adapter.postNote(noteContent);

      verify(() => mockBrowser.navigate('https://substack.com/notes')).called(1);
      verify(() => mockBrowser.typeIntoElement(any(), noteContent)).called(1);
      // clickElement is called twice: once for compose area, once for Post button
      verify(() => mockBrowser.clickElement(any())).called(2);
    });

    test('throws StateError when adapter is not initialized', () async {
      await expectLater(
        () => adapter.postNote('Test note'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when compose area not found', () async {
      final emptySnapshot = SnapshotElement(
        ref: 'root',
        role: 'document',
        children: [],
      );

      stubInitialize();
      when(() => mockBrowser.snapshot())
          .thenAnswer((_) async => emptySnapshot);

      await adapter.initialize();

      await expectLater(
        () => adapter.postNote('Test note'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when Post button not found', () async {
      final composeArea = SnapshotElement(
        ref: 'e1',
        role: 'textbox',
        name: 'Note',
      );
      // Both snapshot calls return the same snapshot — no Post button present
      final snapshotNoPostButton = SnapshotElement(
        ref: 'root',
        role: 'document',
        children: [composeArea],
      );

      stubInitialize();
      when(() => mockBrowser.snapshot())
          .thenAnswer((_) async => snapshotNoPostButton);
      when(() => mockBrowser.clickElement(any())).thenAnswer((_) async {});
      when(() => mockBrowser.typeIntoElement(any(), any()))
          .thenAnswer((_) async {});

      await adapter.initialize();

      await expectLater(
        () => adapter.postNote('Test note'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
