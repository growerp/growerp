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
import '../../authenticate/blocs/auth_bloc.dart';
import '../../../services/chat_server.dart';

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
  final ChatServer chatServer;
  final AuthBloc authBloc;
  int start = 0;

  ChatRoomBloc(this.restClient, this.chatServer, this.authBloc)
      : super(const ChatRoomState()) {
    on<ChatRoomFetch>(_onChatRoomFetch,
        transformer: chatRoomDroppable(const Duration(milliseconds: 100)));
    on<ChatRoomUpdate>(_onChatRoomUpdate);
    on<ChatRoomDelete>(_onChatRoomDelete);
    on<ChatRoomReceiveWsChatMessage>(_onChatRoomReceiveWsChatMessage);
  }

  Future<void> _onChatRoomFetch(
    ChatRoomFetch event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') {
      return;
    }
    if (state.status == ChatRoomStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.chatRooms.length;
    }
    if (state.status == ChatRoomStatus.initial) {
      final myStream = chatServer.stream();
      myStream.listen((data) => add(ChatRoomReceiveWsChatMessage(
          WsChatMessage.fromJson(jsonDecode(data)))));
    }
    try {
      // start from record zero for initial and refresh

      ChatRooms compResult =
          await restClient.getChatRooms(searchString: event.searchString);
      return emit(state.copyWith(
        status: ChatRoomStatus.success,
        chatRooms: start == 0
            ? compResult.chatRooms
            : (List.of(state.chatRooms)..addAll(compResult.chatRooms)),
        hasReachedMax:
            compResult.chatRooms.length < _chatRoomLimit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: getDioError(e)));
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
        ChatRoom compResult =
            await restClient.updateChatRoom(chatRoom: event.chatRoom);
        int index = chatRooms.indexWhere(
            (element) => element.chatRoomId == event.chatRoom.chatRoomId);
        chatRooms[index] = compResult;
        return emit(
            state.copyWith(chatRooms: chatRooms, message: "Chat room updated"));
      } else {
        // add
        List<ChatRoomMember> members = List.of(event.chatRoom.members);
        // private chatroom one to one user exist?
        if (event.chatRoom.chatRoomName == null) {
          // get chatroom where current user and toUserId are members, name is null
          ChatRooms result = await restClient.getChatRooms(
              chatRoomName: ' ', // server should interprete as null
              userId: event.chatRoom.getToUserId(
                  authBloc.state.authenticate?.user?.loginName ?? ''));
          dynamic dbRooms = result.chatRooms;
          if (dbRooms is ChatRoomState) return emit(dbRooms);
          if (dbRooms.isNotEmpty) {
            // update existing chatRoom
            members = [];
            for (ChatRoomMember member in dbRooms[0].members) {
              members.add(member.copyWith(isActive: true));
            }
            await restClient.updateChatRoom(
                chatRoom: dbRooms[0].copyWith(members: members));
            chatRooms.insert(0, dbRooms[0].copyWith(members: members));
            return emit(state.copyWith(
                chatRooms: chatRooms, message: "Chat room added"));
          } else {
            // not found so create new
            // add logged user to members
            members.add(ChatRoomMember(
                member: authBloc.state.authenticate?.user,
                hasRead: true,
                isActive: true));
            ChatRoom compResult = await restClient.createChatRoom(
                chatRoom: event.chatRoom.copyWith(members: members));
            chatRooms.insert(0, compResult);
            return emit(state.copyWith(chatRooms: chatRooms));
          }
        } else {
          // add new multiperson room
          List<ChatRoomMember> members = List.of(event.chatRoom.members);
          members.add(ChatRoomMember(
              member: authBloc.state.authenticate?.user,
              hasRead: true,
              isActive: true));
          ChatRoom compResult = await restClient.createChatRoom(
              chatRoom: event.chatRoom.copyWith(members: members));
          chatRooms.insert(0, compResult);
          return emit(state.copyWith(
              status: ChatRoomStatus.success, chatRooms: chatRooms));
        }
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onChatRoomDelete(
    ChatRoomDelete event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      List<ChatRoom> chatRooms = List.of(state.chatRooms);
      ChatRooms roomsResult = await restClient.getChatRooms(
          chatRoomName: ' ', // server should interprete as null
          userId: event.chatRoom
              .getToUserId(authBloc.state.authenticate?.user?.userId ?? ''));
      int chatRoomIndex = chatRooms
          .indexWhere((cr) => cr.chatRoomId == event.chatRoom.chatRoomId);
      int memberIndex = event.chatRoom
          .getMemberIndex(authBloc.state.authenticate?.user?.userId ?? '');
      roomsResult.chatRooms[0].members[memberIndex] = roomsResult
          .chatRooms[0].members[memberIndex]
          .copyWith(isActive: false, hasRead: true);
      add(ChatRoomUpdate(roomsResult.chatRooms[0]));
      chatRooms.removeAt(chatRoomIndex);
      return emit(state.copyWith(chatRooms: chatRooms));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: getDioError(e)));
    }
  }

/*
  Future<void> _onChatRoomCreate(
    ChatRoomCreate event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      List<ChatRoom> chatRooms = List.from(state.chatRooms);
      // private chatroom exist?
      if (event.chatRoom.chatRoomName == null) {
        // get chatroom where current user and toUserId are members, name is null
        ChatRooms roomsResult = await restClient.getChatRooms(
            chatRoomName: ' ', // server should interprete as null
            userId: event.chatRoom.getToUserId(event.fromUserId));
        dynamic result = roomsResult.chatRooms;
        if (result is ChatRoomState) return emit(result);
        if (result.length == 1) {
          // exist, so activate 2 members
          List<ChatRoomMember> members = [];
          for (ChatRoomMember member in result[0].members) {
            members.add(member.copyWith(isActive: true));
          }
          add(ChatRoomUpdate(
              result[0].copyWith(members: members), event.fromUserId));
        } else {
          // get chatRoom by provided name
          ChatRooms roomsResult = await restClient.getChatRooms(
              chatRoomName: event.chatRoom.chatRoomName,
              userId: event.chatRoom.getToUserId(event.fromUserId));
          if (roomsResult.chatRooms is ChatRoomState) return emit(result);

          if (result.length == 1) {
            // exist so activate all members
            List<ChatRoomMember> members = [];
            for (ChatRoomMember member in result[0].members) {
              members.add(member.copyWith(isActive: true));
            }
            add(ChatRoomUpdate(
                result[0].copyWith(members: members), event.fromUserId));
          } else {
            // add new chatroom
            ChatRoom roomsResult =
                await restClient.createChatRoom(chatRoom:event.chatRoom);
            if (roomsResult is ChatRoomState) return emit(result);
            chatRooms.add(roomsResult);
            emit(state.copyWith(chatRooms: chatRooms));
          }
        }
      } else {
        // new group with name
        ChatRoom roomsResult =
            await restClient.createChatRoom(chatRoom:event.chatRoom);
        dynamic response = roomsResult;
        if (roomsResult is ChatRoomState) return emit(response);
        chatRooms.add(response);
        emit(state.copyWith(chatRooms: chatRooms));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: getDioError(e)));
    }
  }
*/
  Future<void> _onChatRoomReceiveWsChatMessage(
    ChatRoomReceiveWsChatMessage event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      List<ChatRoom> chatRooms = List.from(state.chatRooms);
      if (event.chatMessage.toUserId ==
          authBloc.state.authenticate!.user!.userId) {
        if (state.status == ChatRoomStatus.success) {
          // only take NON system messages
          if (event.chatMessage.chatRoomId != null &&
              event.chatMessage.chatRoomId != "%%system%%") {
            if (!state.chatRooms.any((element) =>
                element.chatRoomId == event.chatMessage.chatRoomId)) {
              ChatRooms roomResult = await restClient.getChatRooms(
                  chatRoomId: event.chatMessage.chatRoomId);
              chatRooms.add(roomResult.chatRooms[0]);
              return emit(state.copyWith(chatRooms: chatRooms));
            }
          }
        }
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ChatRoomStatus.failure,
          chatRooms: [],
          message: getDioError(e)));
    }
  }
}
