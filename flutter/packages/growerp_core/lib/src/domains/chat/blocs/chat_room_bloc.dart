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
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:growerp_core/growerp_core.dart';

part 'chat_room_event.dart';
part 'chat_room_state.dart';

const _chatRoomLimit = 20;

EventTransformer<E> chatRoomDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final RestClient restClient;
  final WsClient chatClient;
  final AuthBloc authBloc;
  int start = 0;
  bool _subscribed = false;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _authSubscription;

  ChatRoomBloc(this.restClient, this.chatClient, this.authBloc)
    : super(const ChatRoomState()) {
    on<ChatRoomUpdateLocal>(_onChatRoomUpdateLocal);
    on<ChatRoomFetch>(
      _onChatRoomFetch,
      transformer: chatRoomDroppable(const Duration(milliseconds: 100)),
    );
    on<ChatRoomUpdate>(_onChatRoomUpdate);
    on<ChatRoomDelete>(_onChatRoomDelete);
    on<ChatRoomReceiveWsChatMessage>(_onChatRoomReceiveWsChatMessage);
    // Reset the WS subscription on logout so the next login re-subscribes.
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.status == AuthStatus.unAuthenticated) {
        _subscribed = false;
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

  void _onChatRoomUpdateLocal(
    ChatRoomUpdateLocal event,
    Emitter<ChatRoomState> emit,
  ) {
    var chatRooms = List.of(state.chatRooms);
    int index = chatRooms.indexWhere(
      (element) =>
          element.chatRoomId ==
          (event.addNotReadChatRoomId ?? event.delNotReadChatRoomId),
    );
    if (index != -1) {
      if (event.addNotReadChatRoomId != null) {
        chatRooms[index] = chatRooms[index].copyWith(hasRead: false);
      } else if (event.delNotReadChatRoomId != null) {
        chatRooms[index] = chatRooms[index].copyWith(hasRead: true);
      }
    }
    return emit(
      state.copyWith(status: ChatRoomStatus.success, chatRooms: chatRooms),
    );
  }

  Future<void> _onChatRoomFetch(
    ChatRoomFetch event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.status == ChatRoomStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.chatRooms.length;
    }
    if (!_subscribed && chatClient.isConnected) {
      _subscribed = true;
      await _wsSubscription?.cancel();
      _wsSubscription = chatClient.stream().listen(
        (data) {
          try {
            add(
              ChatRoomReceiveWsChatMessage(
                ChatMessage.fromJson(jsonDecode(data)),
              ),
            );
          } catch (e) {
            debugPrint('Chat WS parse error: $e');
          }
        },
        onError: (e) => debugPrint('Chat WS stream error: $e'),
        cancelOnError: false,
      );
    }
    try {
      // start from record zero for initial and refresh
      ChatRooms compResult = await restClient.getChatRooms(
        searchString: event.searchString,
        namePrefix: event.namePrefix,
      );
      return emit(
        state.copyWith(
          status: ChatRoomStatus.success,
          chatRooms: start == 0
              ? compResult.chatRooms
              : (List.of(state.chatRooms)..addAll(compResult.chatRooms)),
          hasReachedMax: compResult.chatRooms.length < _chatRoomLimit
              ? true
              : false,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onChatRoomUpdate(
    ChatRoomUpdate event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      List<ChatRoom> chatRooms = List.from(state.chatRooms);
      if (event.chatRoom.chatRoomId.isNotEmpty) {
        // update
        ChatRoom compResult = await restClient.updateChatRoom(
          chatRoom: event.chatRoom,
        );
        int index = chatRooms.indexWhere(
          (element) => element.chatRoomId == event.chatRoom.chatRoomId,
        );
        chatRooms[index] = compResult;
        return emit(
          state.copyWith(
            chatRooms: chatRooms,
            message: 'chatRoomUpdateSuccess',
          ),
        );
      } else {
        // add
        List<ChatRoomMember> members = List.of(event.chatRoom.members);
        // private chatroom one to one user exist?
        if (event.chatRoom.chatRoomName == null) {
          // get chatroom where current user and toUserId are members, name is null
          ChatRooms result = await restClient.getChatRooms(
            chatRoomName: ' ', // server should interprete as null
            userId: event.chatRoom.getToUserId(
              authBloc.state.authenticate?.user?.loginName ?? '',
            ),
          );
          dynamic dbRooms = result.chatRooms;
          if (dbRooms is ChatRoomState) return emit(dbRooms);
          if (dbRooms.isNotEmpty) {
            // update existing chatRoom
            members = [];
            for (ChatRoomMember member in dbRooms[0].members) {
              members.add(member.copyWith(isActive: true));
            }
            await restClient.updateChatRoom(
              chatRoom: dbRooms[0].copyWith(members: members),
            );
            chatRooms.insert(0, dbRooms[0].copyWith(members: members));
            return emit(
              state.copyWith(
                chatRooms: chatRooms,
                message: 'chatRoomAddSuccess',
              ),
            );
          } else {
            // not found so create new
            // add logged user to members
            members.add(
              ChatRoomMember(
                user: authBloc.state.authenticate?.user,
                hasRead: true,
                isActive: true,
              ),
            );
            ChatRoom compResult = await restClient.createChatRoom(
              chatRoom: event.chatRoom.copyWith(members: members),
            );
            chatRooms.insert(0, compResult);
            return emit(state.copyWith(chatRooms: chatRooms));
          }
        } else {
          // add new multiperson room
          List<ChatRoomMember> members = List.of(event.chatRoom.members);
          members.add(
            ChatRoomMember(
              user: authBloc.state.authenticate?.user,
              hasRead: true,
              isActive: true,
            ),
          );
          ChatRoom compResult = await restClient.createChatRoom(
              chatRoom: event.chatRoom.copyWith(members: members),
          );
          chatRooms.insert(0, compResult);
          return emit(
            state.copyWith(
              status: ChatRoomStatus.success,
              chatRooms: chatRooms,
            ),
          );
        }
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onChatRoomDelete(
    ChatRoomDelete event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      List<ChatRoom> chatRooms = List.of(state.chatRooms);
      ChatRoom result = await restClient.deleteChatRoom(
        chatRoomId: event.chatRoom.chatRoomId,
      );
      int chatRoomIndex = chatRooms.indexWhere(
        (cr) => cr.chatRoomId == event.chatRoom.chatRoomId,
      );
      chatRooms.removeAt(chatRoomIndex);
      return emit(
        state.copyWith(
          chatRooms: chatRooms,
          status: ChatRoomStatus.success,
          message: "left chatroom ${result.chatRoomName}",
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onChatRoomReceiveWsChatMessage(
    ChatRoomReceiveWsChatMessage event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      List<ChatRoom> chatRooms = List.from(state.chatRooms);
      // check if room exist for message, when not, get new unread active list
      if (!state.chatRooms.any(
        (element) =>
            element.chatRoomId == event.chatMessage.chatRoom?.chatRoomId,
      )) {
        ChatRooms roomResult = await restClient.getChatRooms();
        chatRooms = roomResult.chatRooms;
      }
      // set badge om roomlist
      add(
        ChatRoomUpdateLocal(
          addNotReadChatRoomId: event.chatMessage.chatRoom?.chatRoomId,
        ),
      );
      return emit(state.copyWith(chatRooms: chatRooms));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}
