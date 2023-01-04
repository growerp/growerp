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

import '../../common/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import '../../domains.dart';

class ChatRoomListDialog extends StatefulWidget {
  const ChatRoomListDialog();
  @override
  _ChatRoomsState createState() => _ChatRoomsState();
}

class _ChatRoomsState extends State<ChatRoomListDialog> {
  final _scrollController = ScrollController();
  double _scrollThreshold = 200.0;
  late ChatRoomBloc _chatRoomBloc;
  List<ChatRoom> chatRooms = [];
  int limit = 20;
  late bool search;
  String searchString = '';
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;

  @override
  void initState() {
    super.initState();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'ChatRoom';
    _scrollController.addListener(_onScroll);
    _chatRoomBloc = context.read<ChatRoomBloc>();
    search = false;
    limit = 20;
  }

  @override
  Widget build(BuildContext context) {
    limit = (MediaQuery.of(context).size.height / 35).round();
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
        listener: (context, state) {
      if (state.status == ChatRoomStatus.failure)
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      if (state.status == ChatRoomStatus.success)
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
    }, builder: (context, state) {
      if (state.status == ChatRoomStatus.success) {
        chatRooms = state.chatRooms;
        return Container(
            padding: EdgeInsets.all(20),
            child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: GestureDetector(
                    onTap: () {},
                    child: Dialog(
                        key: Key('ChatRoomListDialog'),
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
                                  floatingActionButton: FloatingActionButton(
                                      key: Key("addNew"),
                                      onPressed: () async {
                                        await showDialog(
                                            barrierDismissible: true,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ChatRoomDialog(ChatRoom());
                                            });
                                      },
                                      tooltip: 'Add New',
                                      child: Icon(Icons.add)),
                                  backgroundColor: Colors.transparent,
                                  body: roomList(state))),
                          Positioned(
                              top: 5, right: 5, child: DialogCloseButton())
                        ])))));
      }
      return Center(child: CircularProgressIndicator());
    });
  }

  Widget roomList(state) {
    return RefreshIndicator(
        onRefresh: (() async =>
            _chatRoomBloc.add(ChatRoomFetch(refresh: true, limit: limit))),
        child: ListView.builder(
          key: Key('listView'),
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: state.hasReachedMax && chatRooms.isNotEmpty
              ? chatRooms.length + 1
              : chatRooms.length + 2,
          controller: _scrollController,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) return listHeader(context);
            if (index == 1 && chatRooms.isEmpty)
              return Center(
                  heightFactor: 20,
                  child: Text("no ${entityName}s found!",
                      key: Key('empty'), textAlign: TextAlign.center));
            index--;
            return index >= chatRooms.length
                ? BottomLoader()
                : Dismissible(
                    key: Key('chatRoomItem'),
                    direction: DismissDirection.startToEnd,
                    child: ListDetail(
                        index: index,
                        chatRooms: chatRooms,
                        chatRoomBloc: _chatRoomBloc));
          },
        ));
  }

  ListTile listHeader(BuildContext context) {
    return ListTile(
        key: Key("search"),
        onTap: (() {
          setState(() {
            search = !search;
          });
        }),
        leading: Image.asset('assets/images/search.png', height: 30),
        title: search
            ? Row(children: <Widget>[
                SizedBox(
                    width: ResponsiveWrapper.of(context).isSmallerThan(TABLET)
                        ? 150
                        : 250,
                    child: TextField(
                      key: Key("searchField"),
                      textInputAction: TextInputAction.go,
                      autofocus: true,
                      decoration: InputDecoration(
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
                ElevatedButton(
                    child: Text('Search'),
                    onPressed: () {
                      _chatRoomBloc.add(ChatRoomFetch(
                          searchString: searchString, limit: limit));
                    })
              ])
            : Column(children: [
                Row(children: <Widget>[
                  Expanded(
                      child: Text("Chat (group) name",
                          textAlign: TextAlign.center)),
                  if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                    Expanded(
                        child: Text("Status", textAlign: TextAlign.center)),
                  Expanded(child: Text("Public", textAlign: TextAlign.center)),
                  Expanded(
                      child: Text("#Members", textAlign: TextAlign.center)),
                ]),
                Divider(color: Colors.black),
              ]),
        trailing: Text(' '));
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
  const ListDetail({
    Key? key,
    required this.chatRooms,
    required ChatRoomBloc chatRoomBloc,
    required this.index,
  }) : super(key: key);

  final List<ChatRoom> chatRooms;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(chatRooms[index].chatRoomName != null
              ? "${chatRooms[index].chatRoomName![0]}"
              : "?"),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
                child: Text(chatRooms[index].chatRoomName ?? '??'),
                key: Key('chatRoomName$index')),
            if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
              Expanded(
                  child: Text(
                      chatRooms[index].hasRead
                          ? 'All messages read'
                          : 'unread messages',
                      key: Key('hasRead$index'))),
            Expanded(
                child: Center(
                    child: Text(chatRooms[index].isPrivate == true ? 'N' : 'Y',
                        key: Key('isPrivate$index')))),
            Expanded(
                child: Center(
                    child: Text("${chatRooms[index].members.length}",
                        key: Key('nbrMembers$index')))),
          ],
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return ChatDialog(chatRooms[index]);
              });
        },
        trailing: IconButton(
          key: Key('delete$index'),
          icon: Icon(Icons.close),
          onPressed: () {
            context.read<ChatRoomBloc>().add(ChatRoomDelete(chatRooms[index]));
          },
        ));
  }
}
