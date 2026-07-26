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

class ChatTest {
  static Future<void> selectChatRoom(WidgetTester tester) async {
    await CommonTest.tapByTooltip(tester, 'Chat');
  }

  static Future<void> addRooms(
    WidgetTester tester,
    List<ChatRoom> chatRooms, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.chatRooms.isEmpty) {
      // not yet created
      test = test.copyWith(chatRooms: chatRooms);
      expect(
        find.byKey(const Key('chatRoomItem')),
        findsNWidgets(0),
      ); // initial admin
      await enterChatRoomData(tester, chatRooms);
      await PersistFunctions.persistTest(test.copyWith(chatRooms: chatRooms));
    }
    if (check && test.chatRooms[0].chatRoomId.isEmpty) {
      await PersistFunctions.persistTest(
        test.copyWith(
          chatRooms: await checkChatRoomDetail(tester, test.chatRooms),
        ),
      );
    }
  }

  static Future<void> updateRooms(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.chatRooms[0].chatRoomName != test.chatRooms[0].chatRoomName) {
      return;
    }
    List<ChatRoom> updChatRooms = [];
    for (ChatRoom chatRoom in test.chatRooms) {
      updChatRooms.add(
        chatRoom.copyWith(chatRoomName: '${chatRoom.chatRoomName!}u'),
      );
    }
    test = test.copyWith(chatRooms: updChatRooms);
    await enterChatRoomData(tester, test.chatRooms);
    await checkChatRoomDetail(tester, test.chatRooms);
    await PersistFunctions.persistTest(test);
  }

  static Future<void> deleteRooms(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.chatRooms.length;
    await CommonTest.gotoMainMenu(tester);
    await selectChatRoom(tester);
    expect(find.byKey(const Key('chatRoomItem')), findsNWidgets(count));
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.gotoMainMenu(tester);
    await selectChatRoom(tester);
    expect(find.byKey(const Key('chatRoomItem')), findsNWidgets(count - 1));
    PersistFunctions.persistTest(
      test.copyWith(
        chatRooms: test.chatRooms.sublist(0, test.chatRooms.length - 1),
      ),
    );
  }

  static Future<void> sendDirectMessage(WidgetTester tester) async {}

  static Future<void> sendRoomMessage(WidgetTester tester) async {}

  static Future<void> enterChatRoomData(
    WidgetTester tester,
    List<ChatRoom> chatRooms,
  ) async {
    for (ChatRoom chatRoom in chatRooms) {
      if (chatRoom.chatRoomId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: chatRoom.chatRoomId);
        await CommonTest.tapByKey(tester, 'name0');
        expect(
          CommonTest.getTextField('header').split('#')[1],
          chatRoom.chatRoomId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'ChatRoomDialog');
      await CommonTest.enterDropDownSearch(tester, 'userDropDown', 'John');
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<ChatRoom>> checkChatRoomDetail(
    WidgetTester tester,
    List<ChatRoom> chatRooms,
  ) async {
    List<ChatRoom> newChatRooms = [];
    for (ChatRoom chatRoom in chatRooms) {
      await CommonTest.doSearch(tester, searchString: chatRoom.chatRoomName!);
      // list
      expect(CommonTest.getTextField('name0'), equals(chatRoom.chatRoomName));
      var id = CommonTest.getTextField('header').split('#')[1];
      newChatRooms.add(chatRoom.copyWith(chatRoomId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return newChatRooms;
  }
}
