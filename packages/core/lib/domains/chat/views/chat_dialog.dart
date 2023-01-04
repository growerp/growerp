import 'dart:async';

import '../../common/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import '../../../services/chat_server.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domains.dart';

class ChatDialog extends StatefulWidget {
  final ChatRoom chatRoom;

  ChatDialog(this.chatRoom);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<ChatDialog> {
  final _scrollController = ScrollController();
  double _scrollThreshold = 200.0;
  late ChatMessageBloc _chatMessageBloc;
  late Authenticate authenticate;
  late ChatServer? chat;
  int limit = 20;
  late bool search;
  String? searchString;
  List<ChatMessage> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    _chatMessageBloc = context.read<ChatMessageBloc>()
      ..add(ChatMessageFetch(
          chatRoomId: widget.chatRoom.chatRoomId, limit: limit));
    Timer(
      Duration(seconds: 1),
      () => _scrollController.jumpTo(0.0),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    chat = context.read<ChatServer>();
    if (chat == null) return (Center(child: Text("chat not active!")));
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.authenticated)
        authenticate = state.authenticate!;
      return BlocConsumer<ChatMessageBloc, ChatMessageState>(
          listener: ((context, state) {
        if (state.status == ChatMessageStatus.failure)
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }), builder: (context, state) {
        if (state.status == ChatMessageStatus.success ||
            state.status == ChatMessageStatus.failure) {
          messages = state.chatMessages;
          return Container(
              padding: EdgeInsets.all(20),
              child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: GestureDetector(
                      onTap: () {},
                      child: Dialog(
                        key: Key('ChatDialog'),
                        insetPadding: EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child:
                            Stack(clipBehavior: Clip.none, children: <Widget>[
                          Container(
                              padding: EdgeInsets.all(20),
                              width: 500,
                              height: 600,
                              child: Scaffold(
                                backgroundColor: Colors.transparent,
                                body: chatPage(context),
                              )),
                          Positioned(
                              top: 5, right: 5, child: DialogCloseButton())
                        ]),
                      ))));
        } else
          return Center(child: CircularProgressIndicator());
      });
    });
  }

  Container chatPage(BuildContext context) {
    return Container(
        child: Column(children: [
      Center(
          child: Text("To: ${widget.chatRoom.chatRoomName} "
              "#${widget.chatRoom.chatRoomId}")),
      Expanded(
          child: RefreshIndicator(
              onRefresh: (() async => context
                  .read<ChatRoomBloc>()
                  .add(ChatRoomFetch(refresh: true, limit: limit))),
              child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  key: Key('listView'),
                  reverse: true,
                  itemCount: messages.length,
                  controller: _scrollController,
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                        padding: EdgeInsets.only(
                            left: 14, right: 14, top: 10, bottom: 10),
                        child: Align(
                            alignment: (messages[index].fromUserId ==
                                    authenticate.user!.userId
                                ? Alignment.topLeft
                                : Alignment.topRight),
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: (messages[index].fromUserId ==
                                          authenticate.user!.userId
                                      ? Colors.grey.shade200
                                      : Colors.blue[200]),
                                ),
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  messages[index].content ?? '',
                                  style: TextStyle(fontSize: 15),
                                ))));
                  }))),
      SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: TextField(
          key: Key('messageContent'),
          autofocus: true,
          controller: messageController,
          decoration: InputDecoration(labelText: 'Message text..'),
        )),
        SizedBox(
          width: 16,
        ),
        ElevatedButton(
            key: Key('send'),
            child: Text('Send'),
            onPressed: () {
              _chatMessageBloc.add(ChatMessageSendWs(WsChatMessage(
                  toUserId:
                      widget.chatRoom.getToUserId(authenticate.user!.userId!),
                  fromUserId: authenticate.user!.userId!,
                  chatRoomId: widget.chatRoom.chatRoomId,
                  content: messageController.text)));
              messageController.text = '';
              Timer(
                Duration(seconds: 1),
                () => _scrollController.jumpTo(0.0),
              );
            })
      ])
    ]));
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= _scrollThreshold) {
      _chatMessageBloc.add(ChatMessageFetch(
          chatRoomId: widget.chatRoom.chatRoomId,
          limit: limit,
          searchString: searchString));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
