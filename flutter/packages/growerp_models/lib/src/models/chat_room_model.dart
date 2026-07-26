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

import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'chat_room_model.freezed.dart';
part 'chat_room_model.g.dart';

@freezed
abstract class ChatRoom with _$ChatRoom {
  ChatRoom._();
  factory ChatRoom({
    @Default("") String chatRoomId,

    /// will be filled with the 'other' users name when oneToOne chat,
    /// when multiperson room will have the name of the room
    String? chatRoomName,

    /// to easily show last message in list show last message here
    String? lastMessage,
    @Default(true) bool isPrivate,

    /// if all messages were read
    @Default(true) bool hasRead,

    /// userId of the anonymous website visitor, when this room originated
    /// from the public website chat widget (submit#WebsiteChat)
    String? visitorUserId,

    /// list of members in the chat room
    @Default([]) List<ChatRoomMember> members,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json["chatRoom"] ?? json);

  int getMemberIndex(String userId) {
    return members.indexWhere((element) => element.user?.userId == userId);
  }

  String? getToUserId(String currentUserId) {
    ChatRoomMember chatRoomMember = members.firstWhere(
      (element) => element.user?.userId != currentUserId,
      orElse: () => ChatRoomMember(),
    );
    return chatRoomMember.user?.userId;
  }

  String? getFromUserId(String currentUserId) {
    ChatRoomMember chatRoomMember = members.firstWhere(
      (element) => element.user?.userId == currentUserId,
    );
    return chatRoomMember.user?.userId;
  }

  ChatRoomMember? getFromMember(String currentUserId) {
    return members.firstWhere(
      (element) => element.user?.userId == currentUserId,
    );
  }

  int getUserIndex(User user) {
    late int index;
    for (index = 0; index < members.length; index++) {
      if (members[index].user?.userId == user.userId) break;
    }
    return index == members.length ? -1 : index;
  }

  @override
  String toString() => 'ChatRoom name: $chatRoomName[$chatRoomId]';
}
