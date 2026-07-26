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

part of 'chat_message_bloc.dart';

abstract class ChatMessageEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ChatMessageFetch extends ChatMessageEvent {
  final String chatRoomId;
  final String chatRoomName;
  final bool refresh;
  final int limit;
  final String searchString;
  ChatMessageFetch({
    required this.chatRoomId,
    required this.chatRoomName,
    this.refresh = false,
    this.limit = 20,
    this.searchString = '',
  });
  @override
  String toString() =>
      "ChatMessageFetch refresh: $refresh limit: $limit, search: $searchString";
}

class ChatMessageReceiveWs extends ChatMessageEvent {
  final ChatMessage chatMessage;
  ChatMessageReceiveWs(this.chatMessage);
  @override
  String toString() =>
      "ReceiveWsChatMessage receive wsChat message: $chatMessage";
}

class ChatMessageSendWs extends ChatMessageEvent {
  final ChatMessage chatMessage;
  ChatMessageSendWs(this.chatMessage);
  @override
  String toString() => "SendWsChatMessage send wsChat message: $chatMessage";
}
