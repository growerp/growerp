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

import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domains.dart';

class ChatRoomDialog extends StatefulWidget {
  final ChatRoom chatRoom;
  const ChatRoomDialog(this.chatRoom, {super.key});
  @override
  ChatRoomDialogState createState() => ChatRoomDialogState();
}

class ChatRoomDialogState extends State<ChatRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userSearchBoxController =
      TextEditingController();

  bool loading = false;
  User? _selectedUser;
  late DataFetchBloc<Users> _userBloc;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.chatRoom.chatRoomName ?? '';
    _userBloc = context.read<DataFetchBloc<Users>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getUser(limit: 3)));
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    var repos = context.read<RestClient>();
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
          padding: const EdgeInsets.all(20),
          child: Dialog(
            key: const Key('ChatRoomDialog'),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(clipBehavior: Clip.none, children: <Widget>[
              Container(
                  padding: const EdgeInsets.all(20),
                  width: 500,
                  height: 500,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: _showForm(repos, isPhone),
                  )),
              const Positioned(top: 5, right: 5, child: DialogCloseButton())
            ]),
          ));
    });
  }

  Widget _showForm(var repos, bool isPhone) {
    return Center(
        child: Form(
            key: _formKey,
            child: ListView(key: const Key('listView'), children: <Widget>[
              Center(
                  child: Text(
                      "Chat #${widget.chatRoom.chatRoomId.isEmpty ? "New" : widget.chatRoom.chatRoomId}",
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold))),
              const SizedBox(height: 30),
              DropdownSearch<User>(
                key: const Key('userDropDown'),
                popupProps: PopupProps.menu(
                  isFilterOnline: true,
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: "Select chat partner"),
                    controller: _userSearchBoxController,
                  ),
                  title: popUp(
                    context: context,
                    title: 'Select chat partner',
                    height: 50,
                  ),
                ),
                selectedItem: _selectedUser,
                dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration:
                        InputDecoration(labelText: 'Chat partner')),
                itemAsString: (User? u) => " ${u!.firstName} ${u.lastName}",
                asyncItems: (String filter) {
                  _userBloc.add(
                      GetDataEvent(() => context.read<RestClient>().getUser(
                            searchString: filter,
                            limit: 3,
                            isForDropDown: true,
                          )));
                  return Future.delayed(const Duration(milliseconds: 150), () {
                    return Future.value((_userBloc.state.data as Users).users);
                  });
                },
                compareFn: (item, sItem) => item.partyId == sItem.partyId,
                validator: (value) =>
                    _nameController.text.isEmpty && value == null
                        ? 'field required'
                        : null,
                onChanged: (User? newValue) {
                  _selectedUser = newValue;
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                  key: const Key('update'),
                  child: Text(
                      widget.chatRoom.chatRoomId.isEmpty ? 'Create' : 'Update'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && !loading) {
                      context.read<ChatRoomBloc>().add(ChatRoomUpdate(
                              widget.chatRoom.copyWith(
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
            ])));
  }
}
