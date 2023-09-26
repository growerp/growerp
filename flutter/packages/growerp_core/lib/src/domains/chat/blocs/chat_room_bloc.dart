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

part 'chat_room_event.dart';
part 'chat_room_state.dart';

const _chatRoomLimit = 20;

EventTransformer<E> chatRoomDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final APIRepository repos;
  final ChatServer chatServer;
  final AuthBloc authBloc;

  ChatRoomBloc(this.repos, this.chatServer, this.authBloc)
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
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    if (state.status == ChatRoomStatus.initial) {
      final myStream = chatServer.stream();
      myStream.listen((data) => add(ChatRoomReceiveWsChatMessage(
          WsChatMessage.fromJson(jsonDecode(data)))));
    }
    // start from record zero for initial and refresh
    if (state.status == ChatRoomStatus.initial || event.refresh) {
      ApiResult<List<ChatRoom>> compResult =
          await repos.getChatRooms(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) {
            return state.copyWith(
              status: ChatRoomStatus.success,
              chatRooms: data,
              hasReachedMax: data.length < _chatRoomLimit ? true : false,
              searchString: '',
            );
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: ChatRoomStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<ChatRoom>> compResult =
          await repos.getChatRooms(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: ChatRoomStatus.success,
                chatRooms: data,
                hasReachedMax: data.length < _chatRoomLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: ChatRoomStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search

    ApiResult<List<ChatRoom>> compResult =
        await repos.getChatRooms(searchString: event.searchString);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: ChatRoomStatus.success,
              chatRooms: List.of(state.chatRooms)..addAll(data),
              hasReachedMax: data.length < _chatRoomLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: ChatRoomStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onChatRoomUpdate(
    ChatRoomUpdate event,
    Emitter<ChatRoomState> emit,
  ) async {
    List<ChatRoom> chatRooms = List.from(state.chatRooms);
    if (event.chatRoom.chatRoomId.isNotEmpty) {
      // update
      ApiResult<ChatRoom> compResult =
          await repos.updateChatRoom(event.chatRoom);
      return emit(compResult.when(
          success: (data) {
            int index = chatRooms.indexWhere(
                (element) => element.chatRoomId == event.chatRoom.chatRoomId);
            chatRooms[index] = data;
            return state.copyWith(
                chatRooms: chatRooms, message: "Chat room updated");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: ChatRoomStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      List<ChatRoomMember> members = List.of(event.chatRoom.members);
      // private chatroom one to one user exist?
      if (event.chatRoom.chatRoomName == null) {
        // get chatroom where current user and toUserId are members, name is null
        ApiResult<List<ChatRoom>> result = await repos.getChatRooms(
            chatRoomName: ' ', // server should interprete as null
            userId: event.chatRoom.getToUserId(
                authBloc.state.authenticate?.user?.loginName ?? ''));
        dynamic dbRooms = result.when(
            success: (data) => data,
            failure: (NetworkExceptions error) => state.copyWith(
                status: ChatRoomStatus.failure,
                message: NetworkExceptions.getErrorMessage(error)));
        if (dbRooms is ChatRoomState) return emit(dbRooms);
        if (dbRooms.isNotEmpty) {
          // update existing chatRoom
          members = [];
          for (ChatRoomMember member in dbRooms[0].members) {
            members.add(member.copyWith(isActive: true));
          }
          ApiResult<ChatRoom> compResult =
              await repos.updateChatRoom(dbRooms[0].copyWith(members: members));
          return emit(compResult.when(
              success: (data) {
                chatRooms.insert(0, dbRooms[0].copyWith(members: members));
                return state.copyWith(
                    chatRooms: chatRooms, message: "Chat room added");
              },
              failure: (NetworkExceptions error) => state.copyWith(
                  status: ChatRoomStatus.failure,
                  message: NetworkExceptions.getErrorMessage(error))));
        } else {
          // not found so create new
          // add logged user to members
          members.add(ChatRoomMember(
              member: authBloc.state.authenticate?.user,
              hasRead: true,
              isActive: true));
          ApiResult<ChatRoom> compResult = await repos
              .createChatRoom(event.chatRoom.copyWith(members: members));
          return emit(compResult.when(
              success: (data) {
                chatRooms.insert(0, data);
                return state.copyWith(chatRooms: chatRooms);
              },
              failure: (NetworkExceptions error) => state.copyWith(
                  status: ChatRoomStatus.failure,
                  message: NetworkExceptions.getErrorMessage(error))));
        }
      } else {
        // add new multiperson room
        List<ChatRoomMember> members = List.of(event.chatRoom.members);
        members.add(ChatRoomMember(
            member: authBloc.state.authenticate?.user,
            hasRead: true,
            isActive: true));
        ApiResult<ChatRoom> compResult = await repos
            .createChatRoom(event.chatRoom.copyWith(members: members));
        return emit(compResult.when(
            success: (data) {
              chatRooms.insert(0, data);
              return state.copyWith(
                  status: ChatRoomStatus.success, chatRooms: chatRooms);
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: ChatRoomStatus.failure,
                message: NetworkExceptions.getErrorMessage(error))));
      }
    }
  }

  Future<void> _onChatRoomDelete(
    ChatRoomDelete event,
    Emitter<ChatRoomState> emit,
  ) async {
    ApiResult<List<ChatRoom>> roomsResult = await repos.getChatRooms(
        chatRoomName: ' ', // server should interprete as null
        userId: event.chatRoom
            .getToUserId(authBloc.state.authenticate?.user?.userId ?? ''));
    return emit(roomsResult.when(
        success: (data) {
          List<ChatRoom> chatRooms = List.of(state.chatRooms);
          int chatRoomIndex = chatRooms
              .indexWhere((cr) => cr.chatRoomId == event.chatRoom.chatRoomId);
          int memberIndex = event.chatRoom
              .getMemberIndex(authBloc.state.authenticate?.user?.userId ?? '');
          data[0].members[memberIndex] = data[0]
              .members[memberIndex]
              .copyWith(isActive: false, hasRead: true);
          add(ChatRoomUpdate(data[0]));
          chatRooms.removeAt(chatRoomIndex);
          return state.copyWith(chatRooms: chatRooms);
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: ChatRoomStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
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
        ApiResult<List<ChatRoom>> roomsResult = await repos.getChatRooms(
            chatRoomName: ' ', // server should interprete as null
            userId: event.chatRoom.getToUserId(event.fromUserId));
        dynamic result = roomsResult.when(
            success: (data) => data,
            failure: (NetworkExceptions error) => state.copyWith(
                status: ChatRoomStatus.failure, message: error.toString()));
        if (result is ChatRoomState) return emit(result);
        if (result.length == 1) {
          // exist, so activate 2 members
          List<ChatRoomMember> members = [];
          for (ChatRoomMember member in result[0].members)
            members.add(member.copyWith(isActive: true));
          add(ChatRoomUpdate(
              result[0].copyWith(members: members), event.fromUserId));
        } else {
          // get chatRoom by provided name
          ApiResult<List<ChatRoom>> roomsResult = await repos.getChatRooms(
              chatRoomName: event.chatRoom.chatRoomName,
              userId: event.chatRoom.getToUserId(event.fromUserId));
          dynamic response = roomsResult.when(
              success: (data) => data,
              failure: (NetworkExceptions error) => state.copyWith(
                  status: ChatRoomStatus.failure, message: error.toString()));
          if (response is ChatRoomState) return emit(result);

          if (result.length == 1) {
            // exist so activate all members
            List<ChatRoomMember> members = [];
            for (ChatRoomMember member in result[0].members)
              members.add(member.copyWith(isActive: true));
            add(ChatRoomUpdate(
                result[0].copyWith(members: members), event.fromUserId));
          } else {
            // add new chatroom
            ApiResult<ChatRoom> roomsResult =
                await repos.createChatRoom(event.chatRoom);
            dynamic result = roomsResult.when(
                success: (data) => data,
                failure: (NetworkExceptions error) => state.copyWith(
                    status: ChatRoomStatus.failure, message: error.toString()));
            if (result is ChatRoomState) return emit(result);
            chatRooms.add(result);
            emit(state.copyWith(chatRooms: chatRooms));
          }
        }
      } else {
        // new group with name
        ApiResult<ChatRoom> roomsResult =
            await repos.createChatRoom(event.chatRoom);
        dynamic response = roomsResult.when(
            success: (data) => data,
            failure: (NetworkExceptions error) => state.copyWith(
                status: ChatRoomStatus.failure, message: error.toString()));
        if (response is ChatRoomState) return emit(response);
        chatRooms.add(response);
        emit(state.copyWith(chatRooms: chatRooms));
      }
    } catch (error) {
      emit(state.copyWith(
          status: ChatRoomStatus.failure, message: error.toString()));
    }
  }
*/
  Future<void> _onChatRoomReceiveWsChatMessage(
    ChatRoomReceiveWsChatMessage event,
    Emitter<ChatRoomState> emit,
  ) async {
    List<ChatRoom> chatRooms = List.from(state.chatRooms);
    if (event.chatMessage.toUserId ==
        authBloc.state.authenticate!.user!.userId) {
      if (state.status == ChatRoomStatus.success) {
        // only take NON system messages
        if (event.chatMessage.chatRoomId != null &&
            event.chatMessage.chatRoomId != "%%system%%") {
          if (!state.chatRooms.any((element) =>
              element.chatRoomId == event.chatMessage.chatRoomId)) {
            ApiResult<ChatRoom> roomResult = await repos.getChatRoom(
                chatRoomId: event.chatMessage.chatRoomId);
            return emit(roomResult.when(
                success: (data) {
                  chatRooms.add(data);
                  return state.copyWith(chatRooms: chatRooms);
                },
                failure: (NetworkExceptions error) => state.copyWith(
                    status: ChatRoomStatus.failure,
                    message: NetworkExceptions.getErrorMessage(error))));
          }
        }
      }
    }
  }
}
