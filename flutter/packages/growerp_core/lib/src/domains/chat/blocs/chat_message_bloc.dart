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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_rest/growerp_rest.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../authenticate/blocs/auth_bloc.dart';
import '../../../services/chat_server.dart';
import '../../../api_repository.dart';

part 'chat_message_event.dart';
part 'chat_message_state.dart';

const _chatMessageLimit = 20;

EventTransformer<E> chatMessageDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ChatMessageBloc extends Bloc<ChatMessageEvent, ChatMessageState> {
  ChatMessageBloc(this.repos, this.chatServer, this.authBloc)
      : super(const ChatMessageState()) {
    on<ChatMessageFetch>(_onChatMessageFetch,
        transformer: chatMessageDroppable(const Duration(milliseconds: 100)));
    on<ChatMessageReceiveWs>(_onChatMessageReceiveWs);
    on<ChatMessageSendWs>(_onChatMessageSendWs);
  }

  final APIRepository repos;
  final ChatServer chatServer;
  final AuthBloc authBloc;

  Future<void> _onChatMessageFetch(
    ChatMessageFetch event,
    Emitter<ChatMessageState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    if (state.status == ChatMessageStatus.initial) {
      final myStream = chatServer.stream();
      // ignore: unused_local_variable
      final subscription = myStream.listen((data) =>
          add(ChatMessageReceiveWs(WsChatMessage.fromJson(jsonDecode(data)))));
    }
    // start from record zero for initial and refresh
    if (state.status == ChatMessageStatus.initial || event.refresh) {
      ApiResult<List<ChatMessage>> compResult = await repos.getChatMessages(
          chatRoomId: event.chatRoomId, searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: ChatMessageStatus.success,
                chatMessages: data,
                hasReachedMax: data.length < _chatMessageLimit ? true : false,
                searchString: '',
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: ChatMessageStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<ChatMessage>> compResult = await repos.getChatMessages(
          chatRoomId: event.chatRoomId, searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: ChatMessageStatus.success,
                chatMessages: data,
                hasReachedMax: data.length < _chatMessageLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: ChatMessageStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search

    ApiResult<List<ChatMessage>> compResult = await repos.getChatMessages(
        chatRoomId: event.chatRoomId, searchString: event.searchString);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: ChatMessageStatus.success,
              chatMessages: List.of(state.chatMessages)..addAll(data),
              hasReachedMax: data.length < _chatMessageLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: ChatMessageStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onChatMessageReceiveWs(
    ChatMessageReceiveWs event,
    Emitter<ChatMessageState> emit,
  ) async {
    if (event.chatMessage.toUserId ==
        authBloc.state.authenticate!.user!.userId) {
      List<ChatMessage> chatMessages = List.from(state.chatMessages);
      chatMessages.insert(
          0,
          ChatMessage(
            fromUserId: event.chatMessage.fromUserId,
            content: event.chatMessage.content,
          ));
      emit(state.copyWith(chatMessages: chatMessages));
    }
  }

  Future<void> _onChatMessageSendWs(
    ChatMessageSendWs event,
    Emitter<ChatMessageState> emit,
  ) async {
    chatServer.send(event.chatMessage.toJson().toString());
    List<ChatMessage> chatMessages = List.from(state.chatMessages);
    chatMessages.insert(
        0,
        ChatMessage(
          fromUserId: authBloc.state.authenticate!.user!.userId,
          content: event.chatMessage.content,
        ));
    emit(state.copyWith(chatMessages: chatMessages));
  }
}
