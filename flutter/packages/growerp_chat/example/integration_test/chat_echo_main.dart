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
import 'package:growerp_chat/src/chat.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');
  await Hive.initFlutter();

  Bloc.observer = AppBlocObserver();
  runApp(ChatApp(
      restClient: RestClient(await buildDioClient()),
      chatServer: ChatServer('chat')));
}

class ChatApp extends StatelessWidget {
  const ChatApp(
      {super.key,
      required this.restClient,
      required this.chatServer,
      this.company});

  final RestClient restClient;
  final ChatServer chatServer;
  final Company? company;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => chatServer),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
              create: (context) =>
                  AuthBloc(chatServer, restClient, 'AppAdmin', company)
                    ..add(AuthLoad()),
              lazy: false),
          BlocProvider<ChatRoomBloc>(
            create: (context) => ChatRoomBloc(context.read<RestClient>(),
                chatServer, context.read<AuthBloc>())
              ..add(ChatRoomFetch()),
          ),
          BlocProvider<ChatMessageBloc>(
            create: (context) => ChatMessageBloc(context.read<RestClient>(),
                chatServer, context.read<AuthBloc>()),
            lazy: false,
          ),
        ],
        child: const MyChatApp(),
      ),
    );
  }
}

class MyChatApp extends StatelessWidget {
  const MyChatApp({super.key});

  static String title = 'GrowERP Chat echo.';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        //      onGenerateRoute: router.generateRoute,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state.status == AuthStatus.failure) {
              return const FatalErrorForm(
                  message: 'Internet or server problem?');
            }
            if (state.status == AuthStatus.authenticated) {
              return HomeForm(menuOptions: menuOptions, title: title);
            }
            if (state.status == AuthStatus.unAuthenticated) {
              return HomeForm(menuOptions: menuOptions, title: title);
            }
            if (state.status == AuthStatus.changeIp) {
              return const ChangeIpForm();
            }
            return const SplashForm();
          },
        ));
  }
}

List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const ChatRooms(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const ChatRooms(),
  ),
];

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
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
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
                      child: Text('waiting for chats to arrive....',
                          key: Key('empty'), textAlign: TextAlign.center));
                }
                // receive chat message (caused chatroom added on the list)
                _chatMessageBloc = context.read<ChatMessageBloc>()
                  ..add(ChatMessageFetch(
                      chatRoomId: chatRooms[0].chatRoomId, limit: limit));
                return BlocBuilder<ChatMessageBloc, ChatMessageState>(
                    builder: (context, state) {
                  if (state.status == ChatMessageStatus.success) {
                    messages = state.chatMessages;
                    if (chatRooms.isNotEmpty && messages.isNotEmpty) {
                      // echo message
                      _chatMessageBloc.add(ChatMessageSendWs(ChatMessage(
                          toUserId: chatRooms[0]
                              .getToUserId(authenticate.user!.userId!),
                          fromUserId: authenticate.user!.userId!,
                          chatRoom:
                              ChatRoom(chatRoomId: chatRooms[0].chatRoomId),
                          content: messages[0].content!)));
                      // delete chatroom: set not active
                      _chatRoomBloc.add(
                        ChatRoomDelete(chatRooms[0]),
                      );
                      _chatRoomBloc.add(
                        ChatRoomFetch(refresh: true),
                      );
                      chatRooms = [];
                    }
                  }
                  return const Center(child: Text(' processing'));
                });
              } else {
                return const Center(child: Text(' processing'));
              }
            });
      }
      return const Center(child: Text('Not Authorized!'));
    });
  }
}
