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

part of 'chat_room_bloc.dart';

enum ChatRoomStatus { initial, loading, success, failure }

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
  List<Object?> get props => [
    chatRooms,
    hasReachedMax,
    status,
    search,
    message,
  ];

  @override
  String toString() =>
      '$status { #chatRooms: ${chatRooms.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
