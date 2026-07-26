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

enum ChatMessageStatus { initial, success, failure }

class ChatMessageState extends Equatable {
  const ChatMessageState({
    this.status = ChatMessageStatus.initial,
    this.chatMessages = const <ChatMessage>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.search = false,
  });

  final ChatMessageStatus status;
  final String? message;
  final List<ChatMessage> chatMessages;
  final bool hasReachedMax;
  final String searchString;
  final bool search;

  ChatMessageState copyWith({
    ChatMessageStatus? status,
    String? message,
    List<ChatMessage>? chatMessages,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
    bool? search,
  }) {
    return ChatMessageState(
      status: status ?? this.status,
      chatMessages: chatMessages ?? this.chatMessages,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [chatMessages, hasReachedMax, search, message];

  @override
  String toString() =>
      '$status { #chatMessages: ${chatMessages.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
