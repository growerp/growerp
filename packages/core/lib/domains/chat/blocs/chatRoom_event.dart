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

part of 'chatRoom_bloc.dart';

abstract class ChatRoomEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ChatRoomFetch extends ChatRoomEvent {
  final bool refresh;
  final int limit;
  final String searchString;
  ChatRoomFetch(
      {this.refresh = false, this.limit = 20, this.searchString = ''});
  @override
  String toString() =>
      "FetchChatRoom refresh: $refresh limit: $limit, search: $searchString";
}

class ChatRoomUpdate extends ChatRoomEvent {
  final ChatRoom chatRoom;
  ChatRoomUpdate(this.chatRoom);
  @override
  String toString() => "${chatRoom.chatRoomId.isEmpty ? 'Add' : 'Update'}"
      "Room: $chatRoom Members: ${chatRoom.members}";
}

class ChatRoomDelete extends ChatRoomEvent {
  final ChatRoom chatRoom;
  ChatRoomDelete(this.chatRoom);
  @override
  String toString() => "Delete Room: $chatRoom Members: ${chatRoom.members}";
}

class ChatRoomReceiveWsChatMessage extends ChatRoomEvent {
  final WsChatMessage chatMessage;
  ChatRoomReceiveWsChatMessage(this.chatMessage);
  @override
  String toString() =>
      "Receive chat server message in ChatRoombloc ${chatMessage.content} "
      "chatroom: ${chatMessage.chatRoomId} from: ${chatMessage.fromUserId} "
      " to: ${chatMessage.toUserId} ";
}
