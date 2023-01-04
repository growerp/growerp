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
import '../../../services/api_result.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import '../../domains.dart';

import '../../../api_repository.dart';

class ChatRoomDialog extends StatefulWidget {
  final ChatRoom chatRoom;
  ChatRoomDialog(this.chatRoom);
  @override
  _ChatRoomState createState() => _ChatRoomState(chatRoom);
}

class _ChatRoomState extends State<ChatRoomDialog> {
  final ChatRoom chatRoom;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _chatRoomSearchBoxController = TextEditingController();
  TextEditingController _userSearchBoxController = TextEditingController();

  bool loading = false;
  User? _selectedUser;

  _ChatRoomState(this.chatRoom);

  @override
  void initState() {
    super.initState();
    _nameController.text = chatRoom.chatRoomName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    var repos = context.read<APIRepository>();
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
        listener: (context, state) {
      if (state.status == ChatRoomStatus.failure) {
        loading = false;
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
      if (state.status == ChatRoomStatus.success) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        Navigator.of(context).pop();
      }
    }, builder: (BuildContext context, state) {
      return Container(
          padding: EdgeInsets.all(20),
          child: Dialog(
            key: Key('ChatRoomDialog'),
            insetPadding: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(clipBehavior: Clip.none, children: <Widget>[
              Container(
                  padding: EdgeInsets.all(20),
                  width: 500,
                  height: 500,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: _showForm(repos, isPhone),
                  )),
              Positioned(top: 5, right: 5, child: DialogCloseButton())
            ]),
          ));
    });
  }

  Widget _showForm(var repos, bool isPhone) {
    return Center(
        child: Container(
            child: Form(
                key: _formKey,
                child: ListView(key: Key('listView'), children: <Widget>[
                  Center(
                      child: Text(
                          "Chat #" +
                              (chatRoom.chatRoomId.isEmpty
                                  ? "New"
                                  : "${chatRoom.chatRoomId}"),
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold))),
                  SizedBox(height: 30),
                  DropdownSearch<User>(
                    key: Key('userDropDown'),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        autofocus: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0)),
                        ),
                        controller: _userSearchBoxController,
                      ),
                      menuProps:
                          MenuProps(borderRadius: BorderRadius.circular(20.0)),
                      title: Container(
                          height: 50,
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColorDark,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              )),
                          child: Center(
                              child: Text('Select chat partner',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )))),
                    ),
                    selectedItem: _selectedUser,
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Private chat with Other User',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0)),
                    ),
                    showClearButton: false,
                    itemAsString: (User? u) => "${u!.firstName} ${u.lastName}",
                    asyncItems: (String? filter) async {
                      ApiResult<List<User>> result = await repos.getUser(
                          filter: _chatRoomSearchBoxController.text);
                      return result.when(
                          success: (data) => data,
                          failure: (_) => [User(lastName: 'get data error!')]);
                    },
                    validator: (value) =>
                        _nameController.text.isEmpty && value == null
                            ? 'field required'
                            : null,
                    onChanged: (User? newValue) {
                      _selectedUser = newValue;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      key: Key('update'),
                      child: Text(
                          chatRoom.chatRoomId.isEmpty ? 'Create' : 'Update'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate() && !loading) {
                          context.read<ChatRoomBloc>().add(ChatRoomUpdate(
                                  chatRoom.copyWith(
                                      chatRoomName: _nameController.text.isEmpty
                                          ? null
                                          : _nameController.text,
                                      isPrivate: true,
                                      members: [
                                    ChatRoomMember(
                                        member: _selectedUser!, isActive: true)
                                  ])));
                        }
                      }),
                ]))));
  }
}
