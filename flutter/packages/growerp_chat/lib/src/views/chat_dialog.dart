import 'dart:async';

import 'package:growerp_models/growerp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_chat/l10n/generated/chat_localizations.dart';

import '../blocs/blocs.dart';

class ChatDialog extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatDialog(this.chatRoom, {super.key});

  @override
  ChatState createState() => ChatState();
}

class ChatState extends State<ChatDialog> {
  final _scrollController = ScrollController();
  final double _scrollThreshold = 200.0;
  late ChatMessageBloc _chatMessageBloc;
  late Authenticate authenticate;
  late WsClient? chat;
  int limit = 20;
  late bool search;
  String? searchString;
  List<ChatMessage> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    _chatMessageBloc = context.read<ChatMessageBloc>()
      ..add(
        ChatMessageFetch(
          chatRoomId: widget.chatRoom.chatRoomId,
          chatRoomName: widget.chatRoom.chatRoomName!,
          limit: limit,
        ),
      );
    Timer(const Duration(seconds: 1), () => _scrollController.jumpTo(0.0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    chat = context.read<WsClient>();
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    if (chat == null) {
      return (Center(
        child: Text(ChatLocalizations.of(context)!.chatNotActive),
      ));
    }
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          authenticate = state.authenticate!;
        }
        return BlocConsumer<ChatMessageBloc, ChatMessageState>(
          listener: ((context, state) {
            if (state.status == ChatMessageStatus.failure) {
              HelperFunctions.showMessage(
                context,
                '${state.message}',
                Colors.red,
              );
            }
          }),
          builder: (context, state) {
            if (state.status == ChatMessageStatus.success ||
                state.status == ChatMessageStatus.failure) {
              messages = state.chatMessages;
              return Dialog(
                key: const Key('ChatDialog'),
                insetPadding: const EdgeInsets.only(left: 20, right: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                  context: context,
                  title: (widget.chatRoom.chatRoomName ?? '??'),
                  height: 600,
                  width: isPhone ? 300 : 500,
                  child: chatPage(context),
                ),
              );
            } else {
              return const Center(child: LoadingIndicator());
            }
          },
        );
      },
    );
  }

  Widget chatPage(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: (() async => context.read<ChatRoomBloc>().add(
              ChatRoomFetch(refresh: true, limit: limit),
            )),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              key: const Key('listView'),
              reverse: true,
              itemCount: messages.length,
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  padding: const EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment:
                        (messages[index].fromUserId == authenticate.user!.userId
                        ? Alignment.topRight
                        : Alignment.topLeft),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color:
                            (messages[index].fromUserId ==
                                authenticate.user!.userId
                            ? theme.primaryColor
                            : theme.secondaryHeaderColor),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        messages[index].content ?? '',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('messageContent'),
                autofocus: true,
                controller: messageController,
                decoration: InputDecoration(
                  labelText: ChatLocalizations.of(context)!.messageText,
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              key: const Key('send'),
              child: Text(ChatLocalizations.of(context)!.send),
              onPressed: () {
                messageController.text.isEmpty
                    ? null
                    : _chatMessageBloc.add(
                        ChatMessageSendWs(
                          ChatMessage(
                            fromUserId: authenticate.user!.userId!,
                            fromUserFullName: authenticate.user!.fullName!,
                            chatRoom: ChatRoom(
                              chatRoomId: widget.chatRoom.chatRoomId,
                              chatRoomName: widget.chatRoom.chatRoomName,
                            ),
                            content: messageController.text,
                          ),
                        ),
                      );
                messageController.text = '';
                Timer(
                  const Duration(seconds: 1),
                  () => _scrollController.jumpTo(0.0),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= _scrollThreshold) {
      _chatMessageBloc.add(
        ChatMessageFetch(
          chatRoomId: widget.chatRoom.chatRoomId,
          chatRoomName: widget.chatRoom.chatRoomName!,
          limit: limit,
          searchString: searchString ?? '',
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
