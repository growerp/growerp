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

part of 'chat_room_bloc.dart';

enum ChatRoomStatus { initial, success, failure }

class ChatRoomState extends Equatable {
  const ChatRoomState({
    this.status = ChatRoomStatus.initial,
    this.chatRooms = const <ChatRoom>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.search = false,
  });

  final ChatRoomStatus status;
  final String? message;
  final List<ChatRoom> chatRooms;
  final bool hasReachedMax;
  final String searchString;
  final bool search;

  ChatRoomState copyWith({
    ChatRoomStatus? status,
    String? message,
    List<ChatRoom>? chatRooms,
    bool? hasReachedMax,
    String? searchString,
    bool? search,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      chatRooms: chatRooms ?? this.chatRooms,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props =>
      [chatRooms, hasReachedMax, status, search, message];

  @override
  String toString() => '$status { #chatRooms: ${chatRooms.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
