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

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:growerp_core/growerp_core.dart';

part 'chat_message_event.dart';
part 'chat_message_state.dart';

const _chatMessageLimit = 20;

EventTransformer<E> chatMessageDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ChatMessageBloc extends Bloc<ChatMessageEvent, ChatMessageState> {
  ChatMessageBloc(
    this.restClient,
    this.chatClient,
    this.authBloc,
    this.chatRoomBloc,
  ) : super(const ChatMessageState()) {
    on<ChatMessageFetch>(
      _onChatMessageFetch,
      transformer: chatMessageDroppable(const Duration(milliseconds: 100)),
    );
    on<ChatMessageReceiveWs>(_onChatMessageReceiveWs);
    on<ChatMessageSendWs>(_onChatMessageSendWs);
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.status == AuthStatus.unAuthenticated) {
        _wsSubscription?.cancel();
        _wsSubscription = null;
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _wsSubscription?.cancel();
    return super.close();
  }

  final RestClient restClient;
  final WsClient chatClient;
  final AuthBloc authBloc;
  final ChatRoomBloc chatRoomBloc;
  int start = 0;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _authSubscription;

  Future<void> _onChatMessageFetch(
    ChatMessageFetch event,
    Emitter<ChatMessageState> emit,
  ) async {
    if (state.status == ChatMessageStatus.initial) {
      await _wsSubscription?.cancel();
      _wsSubscription = chatClient.stream().listen(
        (data) =>
            add(ChatMessageReceiveWs(ChatMessage.fromJson(jsonDecode(data)))),
        onError: (e) => debugPrint('ChatMessage WS stream error: $e'),
        cancelOnError: false,
      );
    }
    try {
      // Always start from 0 for a fresh fetch (new room or refresh)
      // Only append when scrolling for more messages in the same room
      bool shouldReplace =
          state.status == ChatMessageStatus.initial ||
          event.refresh ||
          event.searchString != '';
      start = shouldReplace ? 0 : state.chatMessages.length;

      ChatMessages compResult = await restClient.getChatMessages(
        chatRoomId: event.chatRoomId,
        searchString: event.searchString,
      );
      // Mark chat room as read (hasRead: true)
      chatRoomBloc.add(
        ChatRoomUpdateLocal(delNotReadChatRoomId: event.chatRoomId),
      );
      return emit(
        state.copyWith(
          status: ChatMessageStatus.success,
          chatMessages: shouldReplace
              ? compResult.chatMessages
              : (List.of(state.chatMessages)..addAll(compResult.chatMessages)),
          hasReachedMax: compResult.chatMessages.length < _chatMessageLimit
              ? true
              : false,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ChatMessageStatus.failure,
          chatMessages: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onChatMessageReceiveWs(
    ChatMessageReceiveWs event,
    Emitter<ChatMessageState> emit,
  ) async {
    List<ChatMessage> chatMessages = List.from(state.chatMessages);
    chatMessages.add(
      ChatMessage(
        fromUserId: event.chatMessage.fromUserId,
        content: event.chatMessage.content,
      ),
    );
    chatRoomBloc.add(
      ChatRoomUpdateLocal(
        addNotReadChatRoomId: event.chatMessage.chatRoom!.chatRoomId,
      ),
    );
    emit(state.copyWith(chatMessages: chatMessages));
  }

  Future<void> _onChatMessageSendWs(
    ChatMessageSendWs event,
    Emitter<ChatMessageState> emit,
  ) async {
    try {
      // no chatClient.send: createChatMessage pushes the message to the other
      // members server side, which also works when this socket went stale
      await restClient.createChatMessage(chatMessage: event.chatMessage);
      List<ChatMessage> chatMessages = List.from(state.chatMessages);
      chatMessages.add(event.chatMessage);
      emit(state.copyWith(chatMessages: chatMessages));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ChatMessageStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
