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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';

import '../blocs/blocs.dart';
import 'views.dart';

class ChatRoomListDialog extends StatefulWidget {
  const ChatRoomListDialog({super.key});
  @override
  ChatRoomListDialogsState createState() => ChatRoomListDialogsState();
}

class ChatRoomListDialogsState extends State<ChatRoomListDialog> {
  final _scrollController = ScrollController();
  final double _scrollThreshold = 200.0;
  late ChatRoomBloc _chatRoomBloc;
  List<ChatRoom> chatRooms = [];
  int limit = 20;
  late bool search;
  String searchString = '';
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;
  late double top, left;

  @override
  void initState() {
    super.initState();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'ChatRoom';
    _scrollController.addListener(_onScroll);
    _chatRoomBloc = context.read<ChatRoomBloc>()
      ..add(const ChatRoomFetch(refresh: true));
    search = false;
    limit = 20;
    top = 400;
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    left = isPhone ? 250 : 700;
    limit = (MediaQuery.of(context).size.height / 35).round();
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
        listener: (context, state) {
      if (state.status == ChatRoomStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
      if (state.status == ChatRoomStatus.success) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
    }, builder: (context, state) {
      if (state.status == ChatRoomStatus.failure) {
        return FatalErrorForm(
            message: 'Error processing ChatRoom: ${state.message}');
      }
      if (state.status == ChatRoomStatus.success) {
        chatRooms = state.chatRooms;
        return Dialog(
            key: const Key('ChatRoomListDialog'),
            insetPadding: const EdgeInsets.only(left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: popUp(
              context: context,
              title: ('Chat users and groups'),
              height: classificationId == 'AppAdmin' ? 550 : 600,
              width: isPhone ? 450 : 800,
              child: Stack(
                children: [
                  roomList(state),
                  Positioned(
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          left += details.delta.dx;
                          top += details.delta.dy;
                        });
                      },
                      child: FloatingActionButton(
                          key: const Key("addNew"),
                          heroTag: "chatRoomAdd",
                          onPressed: () async {
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return ChatRoomDialog(ChatRoom());
                                });
                          },
                          tooltip: 'Add New',
                          child: const Icon(Icons.add)),
                    ),
                  ),
                ],
              ),
            ));
      }
      return const Center(child: LoadingIndicator());
    });
  }

  Widget roomList(state) {
    return ListView.builder(
      key: const Key('listView'),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.hasReachedMax && chatRooms.isNotEmpty
          ? chatRooms.length + 1
          : chatRooms.length + 2,
      controller: _scrollController,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) return listHeader(context);
        if (index == 1 && chatRooms.isEmpty) {
          return Center(
              heightFactor: 20,
              child: Text("no ${entityName}s found!",
                  key: const Key('empty'), textAlign: TextAlign.center));
        }
        index--;
        return index >= chatRooms.length
            ? const BottomLoader()
            : Dismissible(
                key: const Key('chatRoomItem'),
                direction: DismissDirection.startToEnd,
                child: ListDetail(chatRoom: chatRooms[index], index: index));
      },
    );
  }

  ListTile listHeader(BuildContext context) {
    return ListTile(
        key: const Key("search"),
        onTap: (() {
          setState(() {
            search = !search;
          });
        }),
        leading: const Icon(Icons.search_sharp, size: 30),
        title: search
            ? Row(children: <Widget>[
                SizedBox(
                    width:
                        ResponsiveBreakpoints.of(context).isMobile ? 150 : 250,
                    child: TextField(
                      key: const Key("searchField"),
                      textInputAction: TextInputAction.go,
                      autofocus: true,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        hintText: "search in name ..",
                      ),
                      onChanged: ((value) {
                        searchString = value;
                      }),
                      onSubmitted: ((value) {
                        _chatRoomBloc.add(
                            ChatRoomFetch(searchString: value, limit: limit));
                        setState(() {
                          search = !search;
                        });
                      }),
                    )),
                OutlinedButton(
                    child: const Text('Search'),
                    onPressed: () {
                      _chatRoomBloc.add(ChatRoomFetch(
                          searchString: searchString, limit: limit));
                    })
              ])
            : Column(children: [
                Row(children: <Widget>[
                  const Expanded(
                      child: Text("Name", textAlign: TextAlign.center)),
                  if (!ResponsiveBreakpoints.of(context).isMobile)
                    const Text("Status", textAlign: TextAlign.center),
                  const Text("Pvt.", textAlign: TextAlign.center),
                  const Text("#Mem.", textAlign: TextAlign.center),
                  const Text("    ", textAlign: TextAlign.center),
                ]),
                const Divider(),
              ]),
        trailing: const Text(' '));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= _scrollThreshold) {
      _chatRoomBloc
          .add(ChatRoomFetch(limit: limit, searchString: searchString));
    }
  }
}

class ListDetail extends StatelessWidget {
  const ListDetail({super.key, required this.chatRoom, required this.index});

  final ChatRoom chatRoom;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: Badge(
          label: chatRoom.hasRead ? null : const Text('!'),
          child: CircleAvatar(
            child: Text(chatRoom.chatRoomName != null
                ? chatRoom.chatRoomName![0]
                : "?"),
          ),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
                key: Key('chatRoomName$index'),
                child: Text(chatRoom.chatRoomName ?? '??')),
            if (!ResponsiveBreakpoints.of(context).isMobile)
              Text(chatRoom.hasRead ? 'All messages read' : 'unread messages',
                  key: Key('unRead$index')),
            Text(chatRoom.isPrivate != true ? ' N   ' : 'Y   ',
                key: Key('isPrivate$index')),
            Text("${chatRoom.members.length}", key: Key('nbrMembers$index')),
          ],
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return ChatDialog(chatRoom);
              });
        },
        trailing: IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<ChatRoomBloc>().add(ChatRoomDelete(chatRoom));
          },
        ));
  }
}
