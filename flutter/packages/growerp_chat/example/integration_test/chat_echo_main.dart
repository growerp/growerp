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

// start with: flutter run -t lib/chatEcho_main.dart

// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:growerp_chat/growerp_chat.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_models/growerp_models.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  String classificationId = GlobalConfiguration().get("classificationId");

  runApp(
    TopApp(
      classificationId: classificationId,
      restClient: restClient,
      chatClient: chatClient,
      notificationClient: WsClient('notws'),
      title: 'GrowERP Chat echo.',
      router: createChatEchoRouter(),
      extraBlocProviders: [
        BlocProvider<ChatRoomBloc>(
          create: (context) =>
              ChatRoomBloc(restClient, chatClient, context.read<AuthBloc>())
                ..add(const ChatRoomFetch()),
        ),
        BlocProvider<ChatMessageBloc>(
          create: (context) => ChatMessageBloc(
            restClient,
            chatClient,
            context.read<AuthBloc>(),
            context.read<ChatRoomBloc>(),
          ),
          lazy: false,
        ),
      ],
    ),
  );
}

const chatEchoMenuConfig = MenuConfiguration(
  menuConfigurationId: 'CHAT_ECHO_EXAMPLE',
  appId: 'chat_echo_example',
  name: 'Chat Echo Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'CHAT_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
  ],
);

GoRouter createChatEchoRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      if (authState.status != AuthStatus.authenticated && state.path != '/') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return DisplayMenuItem(
              menuConfiguration: chatEchoMenuConfig,
              menuIndex: 0,
              child: const ChatRooms(),
            );
          } else {
            return HomeForm(
              menuConfiguration: chatEchoMenuConfig,
              title: 'GrowERP Chat echo.',
            );
          }
        },
      ),
    ],
  );
}

class ChatRooms extends StatefulWidget {
  const ChatRooms({super.key});

  @override
  ChatRoomsEchoState createState() => ChatRoomsEchoState();
}

class ChatRoomsEchoState extends State<ChatRooms> {
  late ChatRoomBloc _chatRoomBloc;
  List<ChatMessage> messages = [];
  late Authenticate authenticate;
  late ChatMessageBloc _chatMessageBloc;
  List<ChatRoom> chatRooms = [];
  int limit = 20;
  late bool search;
  String? searchString;
  String classificationId = GlobalConfiguration().getValue('classificationId');
  late String entityName;

  @override
  void initState() {
    super.initState();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'ChatRoom';
    _chatRoomBloc = context.read<ChatRoomBloc>();
    search = false;
    limit = 20;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          authenticate = state.authenticate!;
          return BlocConsumer<ChatRoomBloc, ChatRoomState>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state.status == ChatRoomStatus.failure) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state.status == ChatRoomStatus.success) {
                chatRooms = state.chatRooms;
                if (chatRooms.isEmpty) {
                  return const Center(
                    heightFactor: 20,
                    child: Text(
                      'waiting for chats to arrive....',
                      key: Key('empty'),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                // receive chat message (caused chatroom added on the list)
                _chatMessageBloc = context.read<ChatMessageBloc>()
                  ..add(
                    ChatMessageFetch(
                      chatRoomName: chatRooms[0].chatRoomName!,
                      chatRoomId: chatRooms[0].chatRoomId,
                      limit: limit,
                    ),
                  );
                return BlocBuilder<ChatMessageBloc, ChatMessageState>(
                  builder: (context, state) {
                    if (state.status == ChatMessageStatus.success) {
                      messages = state.chatMessages;
                      if (chatRooms.isNotEmpty && messages.isNotEmpty) {
                        // echo message
                        _chatMessageBloc.add(
                          ChatMessageSendWs(
                            ChatMessage(
                              fromUserId: authenticate.user!.userId!,
                              chatRoom: ChatRoom(
                                chatRoomId: chatRooms[0].chatRoomId,
                              ),
                              content: messages[0].content!,
                            ),
                          ),
                        );
                        // delete chatroom: set not active
                        _chatRoomBloc.add(ChatRoomDelete(chatRooms[0]));
                        _chatRoomBloc.add(const ChatRoomFetch(refresh: true));
                        chatRooms = [];
                      }
                    }
                    return const Center(child: Text(' processing'));
                  },
                );
              } else {
                return const Center(child: Text(' processing'));
              }
            },
          );
        }
        return const Center(child: Text('Not Authorized!'));
      },
    );
  }
}
