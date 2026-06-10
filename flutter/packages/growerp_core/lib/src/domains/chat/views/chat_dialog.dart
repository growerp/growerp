import 'dart:async';

import 'package:growerp_models/growerp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';

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
  CoreLocalizations? _localizations;

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    _chatMessageBloc = context.read<ChatMessageBloc>()
      ..add(
        ChatMessageFetch(
          chatRoomId: widget.chatRoom.chatRoomId,
          chatRoomName: widget.chatRoom.chatRoomName!,
          limit: limit,
          refresh: true, // Always refresh when opening a chat room
        ),
      );
    Timer(const Duration(seconds: 1), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = CoreLocalizations.of(context);
    chat = context.read<WsClient>();
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    if (chat == null) {
      return (Center(
        child: Text(_localizations?.chatNotActive ?? 'Chat not active'),
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
    final ordered = messages;
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
              itemCount: ordered.length,
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              itemBuilder: (BuildContext context, int index) {
                final raw = ordered[index].content ?? '';
                final msgFromUserId = ordered[index].fromUserId;
                final onRight = msgFromUserId == authenticate.user!.userId;
                final bubbleColor = onRight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondaryContainer;
                final textColor = onRight
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSecondaryContainer;
                return Container(
                  padding: const EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 6,
                    bottom: 6,
                  ),
                  child: Align(
                    alignment: onRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Column(
                        crossAxisAlignment: onRight
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 4, right: 4, bottom: 2),
                            child: Text(
                              msgFromUserId == 'SYSTEM_SUPPORT'
                                  ? 'System Support'
                                  : onRight
                                      ? 'You'
                                      : ordered[index].fromUserFullName ??
                                          'Other',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft:
                                    Radius.circular(onRight ? 16 : 4),
                                bottomRight:
                                    Radius.circular(onRight ? 4 : 16),
                              ),
                              color: bubbleColor,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: _buildContent(
                                raw, textColor, bubbleColor),
                          ),
                        ],
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
                  labelText: _localizations?.messageText ?? 'Message text',
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              key: const Key('send'),
              child: Text(_localizations?.send ?? 'Send'),
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
                  () {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  String _stripContent(String raw) {
    // Strip complete fences first
    final stripped = raw.replaceAllMapped(
      RegExp(r'```\w*\n?([\s\S]*?)```', dotAll: true),
      (m) => m.group(1) ?? '',
    );
    if (stripped != raw) return stripped.trim();
    // Handle truncated content: opening fence with no closing fence
    return raw.replaceFirst(RegExp(r'^```\w*\n?'), '').trim();
  }

  Widget _buildContent(String raw, Color textColor, Color bubbleColor) {
    final text = _stripContent(raw);
    return Text(text, style: TextStyle(fontSize: 15, color: textColor));
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll <= _scrollThreshold) {
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
