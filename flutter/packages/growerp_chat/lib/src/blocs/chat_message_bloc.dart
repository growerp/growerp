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

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:growerp_core/growerp_core.dart';

import 'chat_room_bloc.dart';

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
      this.restClient, this.chatClient, this.authBloc, this.chatRoomBloc)
      : super(const ChatMessageState()) {
    on<ChatMessageFetch>(_onChatMessageFetch,
        transformer: chatMessageDroppable(const Duration(milliseconds: 100)));
    on<ChatMessageReceiveWs>(_onChatMessageReceiveWs);
    on<ChatMessageSendWs>(_onChatMessageSendWs);
  }

  final RestClient restClient;
  final WsClient chatClient;
  final AuthBloc authBloc;
  final ChatRoomBloc chatRoomBloc;
  int start = 0;

  Future<void> _onChatMessageFetch(
    ChatMessageFetch event,
    Emitter<ChatMessageState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    if (state.status == ChatMessageStatus.initial) {
      final myStream = chatClient.stream();
      // ignore: unused_local_variable
      final subscription = myStream.listen((data) =>
          add(ChatMessageReceiveWs(ChatMessage.fromJson(jsonDecode(data)))));
    }
    try {
      // start from record zero for initial and refresh
      if (state.status == ChatMessageStatus.initial ||
          event.refresh ||
          event.searchString != '') {
        start = 0;
      } else {
        start = state.chatMessages.length;
      }
      ChatMessages compResult = await restClient.getChatMessages(
          chatRoomId: event.chatRoomId, searchString: event.searchString);
      // reset badges
      chatRoomBloc
          .add(ChatRoomUpdateLocal(addNotReadChatRoomId: event.chatRoomId));
      chatRoomBloc
          .add(ChatRoomUpdateLocal(delNotReadChatRoomId: event.chatRoomId));
      return emit(state.copyWith(
        status: ChatMessageStatus.success,
        chatMessages: start == 0
            ? compResult.chatMessages
            : (List.of(state.chatMessages)..addAll(compResult.chatMessages)),
        hasReachedMax:
            compResult.chatMessages.length < _chatMessageLimit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ChatMessageStatus.failure,
          chatMessages: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onChatMessageReceiveWs(
    ChatMessageReceiveWs event,
    Emitter<ChatMessageState> emit,
  ) async {
    List<ChatMessage> chatMessages = List.from(state.chatMessages);
    chatMessages.insert(
        0,
        ChatMessage(
          fromUserId: event.chatMessage.fromUserId,
          content: event.chatMessage.content,
        ));
    chatRoomBloc.add(ChatRoomUpdateLocal(
        addNotReadChatRoomId: event.chatMessage.chatRoom!.chatRoomId));
    emit(state.copyWith(chatMessages: chatMessages));
  }

  Future<void> _onChatMessageSendWs(
    ChatMessageSendWs event,
    Emitter<ChatMessageState> emit,
  ) async {
    try {
      chatClient.send(event.chatMessage);
      await restClient.createChatMessage(chatMessage: event.chatMessage);
      List<ChatMessage> chatMessages = List.from(state.chatMessages);
      if (chatMessages.isEmpty) {
        chatMessages.add(event.chatMessage);
      } else {
        chatMessages.insert(0, event.chatMessage);
      }
      emit(state.copyWith(chatMessages: chatMessages));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ChatMessageStatus.failure, message: await getDioError(e)));
    }
  }
}
