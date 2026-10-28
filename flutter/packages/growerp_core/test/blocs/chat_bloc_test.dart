import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// ChatRoomFetch / ChatMessageFetch are throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<ChatRoomState> roomState({
  ChatRoomStatus? status,
  List<ChatRoom>? rooms,
  String? message,
}) {
  var m = isA<ChatRoomState>();
  if (status != null) m = m.having((s) => s.status, 'status', status);
  if (rooms != null) m = m.having((s) => s.chatRooms, 'chatRooms', rooms);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;
  late MockWsClient wsClient;
  late MockAuthBloc authBloc;
  late StreamController<dynamic> wsStream;

  final me = User(userId: 'me', loginName: 'me@x.com', firstName: 'Me');
  final other = User(userId: 'other', firstName: 'Other');
  final room1 = ChatRoom(chatRoomId: 'R1', chatRoomName: 'Sales');
  final room2 = ChatRoom(chatRoomId: 'R2', chatRoomName: 'Support');

  setUpAll(() {
    registerFallbackValue(ChatRoom());
    registerFallbackValue(const ChatRoomUpdateLocal());
  });

  setUp(() {
    restClient = MockRestClient();
    wsClient = MockWsClient();
    authBloc = MockAuthBloc();
    wsStream = StreamController<dynamic>.broadcast();
    when(() => wsClient.stream()).thenAnswer((_) => wsStream.stream);
    when(() => wsClient.subscribe(any())).thenReturn(null);
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: AuthState(
        status: AuthStatus.authenticated,
        authenticate: Authenticate(user: me),
      ),
    );
  });
  tearDown(() => wsStream.close());

  group('ChatRoomFetch', () {
    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomFetch_initial_listensToWsAndEmitsRooms',
      setUp: () => when(
        () => restClient.getChatRooms(searchString: '', start: 0, limit: 20),
      ).thenAnswer((_) async => ChatRooms(chatRooms: [room1, room2])),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      act: (bloc) => bloc.add(const ChatRoomFetch()),
      wait: fetchWait,
      expect: () => [
        roomState(
          status: ChatRoomStatus.success,
          rooms: [room1, room2],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
      verify: (_) => verify(() => wsClient.stream()).called(1),
    );

    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getChatRooms(searchString: '', start: 0, limit: 20),
      ).thenThrow(dioError('Chat down')),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      act: (bloc) => bloc.add(const ChatRoomFetch()),
      wait: fetchWait,
      expect: () => [
        roomState(
          status: ChatRoomStatus.failure,
          rooms: [],
          message: 'Chat down',
        ),
      ],
    );

    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomFetch_wsMessageForKnownRoom_marksRoomUnread',
      setUp: () => when(
        () => restClient.getChatRooms(searchString: '', start: 0, limit: 20),
      ).thenAnswer((_) async => ChatRooms(chatRooms: [room1])),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      act: (bloc) async {
        bloc.add(const ChatRoomFetch());
        await Future<void>.delayed(fetchWait);
        wsStream.add(
          jsonEncode(ChatMessage(chatRoom: room1, content: 'hi').toJson()),
        );
      },
      wait: fetchWait,
      verify: (bloc) => expect(bloc.state.chatRooms.single.hasRead, isFalse),
    );
  });

  // https://github.com/growerp/growerp/issues/42
  group('ChatRoomFetch paging', () {
    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomFetch_nextPage_requestsFromCurrentLength',
      setUp: () => when(
        () => restClient.getChatRooms(searchString: '', start: 1, limit: 20),
      ).thenAnswer((_) async => ChatRooms(chatRooms: [room2])),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      seed: () =>
          ChatRoomState(status: ChatRoomStatus.success, chatRooms: [room1]),
      act: (bloc) => bloc.add(const ChatRoomFetch()),
      wait: fetchWait,
      expect: () => [
        roomState(rooms: [room1, room2]),
      ],
    );
  });

  group('ChatRoomUpdateLocal', () {
    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomUpdateLocal_addNotRead_setsHasReadFalse',
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      seed: () =>
          ChatRoomState(chatRooms: [room1.copyWith(hasRead: true), room2]),
      act: (bloc) =>
          bloc.add(const ChatRoomUpdateLocal(addNotReadChatRoomId: 'R1')),
      expect: () => [
        isA<ChatRoomState>().having(
          (s) => s.chatRooms.first.hasRead,
          'hasRead',
          false,
        ),
      ],
    );

    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomUpdateLocal_delNotRead_setsHasReadTrue',
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      seed: () => ChatRoomState(chatRooms: [room1.copyWith(hasRead: false)]),
      act: (bloc) =>
          bloc.add(const ChatRoomUpdateLocal(delNotReadChatRoomId: 'R1')),
      expect: () => [
        isA<ChatRoomState>().having(
          (s) => s.chatRooms.first.hasRead,
          'hasRead',
          true,
        ),
      ],
    );
  });

  group('ChatRoomUpdate', () {
    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomUpdate_existingRoom_replacesIt',
      setUp: () => when(
        () => restClient.updateChatRoom(
          chatRoom: room1.copyWith(chatRoomName: 'Sales team'),
        ),
      ).thenAnswer((_) async => room1.copyWith(chatRoomName: 'Sales team')),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      seed: () => ChatRoomState(chatRooms: [room1, room2]),
      act: (bloc) =>
          bloc.add(ChatRoomUpdate(room1.copyWith(chatRoomName: 'Sales team'))),
      expect: () => [
        roomState(
          rooms: [
            room1.copyWith(chatRoomName: 'Sales team'),
            room2,
          ],
          message: 'chatRoomUpdateSuccess',
        ),
      ],
    );

    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomUpdate_newGroupRoom_addsCurrentUserAsMember',
      setUp: () => when(
        () => restClient.createChatRoom(chatRoom: any(named: 'chatRoom')),
      ).thenAnswer((_) async => room2),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      act: (bloc) => bloc.add(
        ChatRoomUpdate(
          ChatRoom(
            chatRoomName: 'Support',
            members: [ChatRoomMember(user: other)],
          ),
        ),
      ),
      expect: () => [
        roomState(status: ChatRoomStatus.success, rooms: [room2]),
      ],
      verify: (_) {
        final sent =
            verify(
                  () => restClient.createChatRoom(
                    chatRoom: captureAny(named: 'chatRoom'),
                  ),
                ).captured.single
                as ChatRoom;
        expect(sent.members.map((m) => m.user?.userId), ['other', 'me']);
      },
    );

    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomUpdate_privateRoomExists_reactivatesMembers',
      setUp: () {
        final existing = ChatRoom(
          chatRoomId: 'R3',
          members: [
            ChatRoomMember(user: me, isActive: false),
            ChatRoomMember(user: other, isActive: false),
          ],
        );
        when(
          () => restClient.getChatRooms(chatRoomName: ' ', userId: 'other'),
        ).thenAnswer((_) async => ChatRooms(chatRooms: [existing]));
        when(
          () => restClient.updateChatRoom(chatRoom: any(named: 'chatRoom')),
        ).thenAnswer((_) async => existing);
      },
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      act: (bloc) => bloc.add(
        ChatRoomUpdate(ChatRoom(members: [ChatRoomMember(user: other)])),
      ),
      expect: () => [
        roomState(message: 'chatRoomAddSuccess').having(
          (s) => s.chatRooms.single.members.every((m) => m.isActive == true),
          'all members active',
          isTrue,
        ),
      ],
    );

    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createChatRoom(chatRoom: any(named: 'chatRoom')),
      ).thenThrow(dioError('Not allowed')),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      act: (bloc) => bloc.add(ChatRoomUpdate(ChatRoom(chatRoomName: 'X'))),
      expect: () => [
        roomState(status: ChatRoomStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  group('ChatRoomDelete', () {
    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomDelete_room_leavesAndRemovesIt',
      setUp: () => when(
        () => restClient.deleteChatRoom(chatRoomId: 'R1'),
      ).thenAnswer((_) async => room1),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      seed: () => ChatRoomState(chatRooms: [room1, room2]),
      act: (bloc) => bloc.add(ChatRoomDelete(room1)),
      expect: () => [
        roomState(
          status: ChatRoomStatus.success,
          rooms: [room2],
          message: 'left chatroom Sales',
        ),
      ],
    );

    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteChatRoom(chatRoomId: 'R1'),
      ).thenThrow(dioError('Not a member')),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      seed: () => ChatRoomState(chatRooms: [room1]),
      act: (bloc) => bloc.add(ChatRoomDelete(room1)),
      expect: () => [
        roomState(status: ChatRoomStatus.failure, message: 'Not a member'),
      ],
    );
  });

  group('ChatRoomReceiveWsChatMessage', () {
    blocTest<ChatRoomBloc, ChatRoomState>(
      'ChatRoomReceiveWsChatMessage_unknownRoom_reloadsRoomsAndMarksUnread',
      setUp: () => when(
        () => restClient.getChatRooms(),
      ).thenAnswer((_) async => ChatRooms(chatRooms: [room1, room2])),
      build: () => ChatRoomBloc(restClient, wsClient, authBloc),
      seed: () => ChatRoomState(chatRooms: [room1]),
      act: (bloc) =>
          bloc.add(ChatRoomReceiveWsChatMessage(ChatMessage(chatRoom: room2))),
      verify: (bloc) {
        expect(bloc.state.chatRooms.map((r) => r.chatRoomId), ['R1', 'R2']);
        expect(bloc.state.chatRooms.last.hasRead, isFalse);
      },
    );
  });

  group('ChatMessageBloc', () {
    late MockChatRoomBloc chatRoomBloc;
    final msg1 = ChatMessage(chatMessageId: 'M1', content: 'hello');
    final msg2 = ChatMessage(chatMessageId: 'M2', content: 'world');

    setUp(() => chatRoomBloc = MockChatRoomBloc());

    ChatMessageBloc build() =>
        ChatMessageBloc(restClient, wsClient, authBloc, chatRoomBloc);

    blocTest<ChatMessageBloc, ChatMessageState>(
      'ChatMessageFetch_room_loadsMessagesAndMarksRoomRead',
      setUp: () => when(
        () => restClient.getChatMessages(
          chatRoomId: 'R1',
          searchString: '',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer((_) async => ChatMessages(chatMessages: [msg1, msg2])),
      build: build,
      act: (bloc) =>
          bloc.add(ChatMessageFetch(chatRoomId: 'R1', chatRoomName: 'Sales')),
      wait: fetchWait,
      expect: () => [
        isA<ChatMessageState>()
            .having((s) => s.status, 'status', ChatMessageStatus.success)
            .having((s) => s.chatMessages, 'chatMessages', [msg1, msg2]),
      ],
      verify: (_) => verify(
        () => chatRoomBloc.add(
          const ChatRoomUpdateLocal(delNotReadChatRoomId: 'R1'),
        ),
      ).called(1),
    );

    blocTest<ChatMessageBloc, ChatMessageState>(
      'ChatMessageFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getChatMessages(
          chatRoomId: 'R1',
          searchString: '',
          start: 0,
          limit: 20,
        ),
      ).thenThrow(dioError('Chat down')),
      build: build,
      act: (bloc) =>
          bloc.add(ChatMessageFetch(chatRoomId: 'R1', chatRoomName: 'Sales')),
      wait: fetchWait,
      expect: () => [
        isA<ChatMessageState>()
            .having((s) => s.status, 'status', ChatMessageStatus.failure)
            .having((s) => s.message, 'message', 'Chat down'),
      ],
    );

    blocTest<ChatMessageBloc, ChatMessageState>(
      'ChatMessageSendWs_message_postsAndAppends',
      setUp: () => when(
        () => restClient.createChatMessage(chatMessage: msg2),
      ).thenAnswer((_) async => msg2),
      build: build,
      seed: () => ChatMessageState(chatMessages: [msg1]),
      act: (bloc) => bloc.add(ChatMessageSendWs(msg2)),
      expect: () => [
        isA<ChatMessageState>().having((s) => s.chatMessages, 'chatMessages', [
          msg1,
          msg2,
        ]),
      ],
    );

    blocTest<ChatMessageBloc, ChatMessageState>(
      'ChatMessageSendWs_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createChatMessage(chatMessage: msg2),
      ).thenThrow(dioError('Room closed')),
      build: build,
      act: (bloc) => bloc.add(ChatMessageSendWs(msg2)),
      expect: () => [
        isA<ChatMessageState>()
            .having((s) => s.status, 'status', ChatMessageStatus.failure)
            .having((s) => s.message, 'message', 'Room closed'),
      ],
    );

    blocTest<ChatMessageBloc, ChatMessageState>(
      'ChatMessageReceiveWs_messageForOpenRoom_appendsIt',
      build: build,
      seed: () => ChatMessageState(chatMessages: [msg1], chatRoomId: 'R1'),
      act: (bloc) => bloc.add(
        ChatMessageReceiveWs(
          ChatMessage(chatRoom: room1, fromUserId: 'other', content: 'new'),
        ),
      ),
      expect: () => [
        isA<ChatMessageState>().having(
          (s) => s.chatMessages.map((m) => m.content),
          'contents',
          ['hello', 'new'],
        ),
      ],
    );

    // https://github.com/growerp/growerp/issues/42
    group('other rooms', () {
      blocTest<ChatMessageBloc, ChatMessageState>(
        'ChatMessageReceiveWs_messageForOtherRoom_doesNotAppend',
        setUp: () => when(
          () => restClient.getChatMessages(
            chatRoomId: 'R1',
            searchString: '',
            start: 0,
            limit: 20,
          ),
        ).thenAnswer((_) async => ChatMessages(chatMessages: [msg1])),
        build: build,
        act: (bloc) async {
          bloc.add(ChatMessageFetch(chatRoomId: 'R1', chatRoomName: 'Sales'));
          await Future<void>.delayed(fetchWait);
          bloc.add(ChatMessageReceiveWs(ChatMessage(chatRoom: room2)));
        },
        wait: fetchWait,
        verify: (bloc) => expect(bloc.state.chatMessages, [msg1]),
      );
    });
  });
}
