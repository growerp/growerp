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

part 'chat_room_member_model.freezed.dart';
part 'chat_room_member_model.g.dart';

@freezed
abstract class ChatRoomMember with _$ChatRoomMember {
  ChatRoomMember._();
  factory ChatRoomMember({User? user, bool? hasRead, bool? isActive}) =
      _ChatRoomMember;

  factory ChatRoomMember.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomMemberFromJson(json['chatRoomMember'] ?? json);

  @override
  String toString() =>
      'ChatRoom Member: ${user?.firstName} ${user?.lastName} '
      'userId: ${user?.userId} partyId: ${user?.partyId}';
}
