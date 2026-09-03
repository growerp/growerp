/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

class ChatRoomDialog extends StatefulWidget {
  final ChatRoom chatRoom;
  const ChatRoomDialog(this.chatRoom, {super.key});
  @override
  ChatRoomDialogState createState() => ChatRoomDialogState();
}

class ChatRoomDialogState extends State<ChatRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool loading = false;
  User? _selectedUser;
  late DataFetchBloc<Users> _userBloc;
  CoreLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.chatRoom.chatRoomName ?? '';
    _userBloc = context.read<DataFetchBloc<Users>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getUser(
            limit: 3,
            isForDropDown: true,
            loginOnly: true,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    _localizations = CoreLocalizations.of(context);
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
      listener: (context, state) {
        if (state.status == ChatRoomStatus.failure) {
          loading = false;
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == ChatRoomStatus.success) {
          HelperFunctions.showMessage(
            context,
            translateChatRoomBlocMessage(state.message, _localizations!),
            Colors.green,
          );
          Navigator.of(context).pop();
        }
      },
      builder: (BuildContext context, state) {
        return Dialog(
          key: const Key('ChatRoomDialog'),
          insetPadding: const EdgeInsets.only(left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: popUp(
            context: context,
            title: _localizations?.addPartner ?? 'Add Partner',
            height: 600,
            width: isPhone ? 300 : 800,
            child: _showForm(isPhone),
          ),
        );
      },
    );
  }

  Widget _showForm(bool isPhone) {
    return Center(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('listView'),
          children: <Widget>[
            Center(
              child: Text(
                "${_localizations?.chatRoomHeader ?? 'Chat #'} #${widget.chatRoom.chatRoomId.isEmpty ? _localizations?.newChat ?? 'New Chat' : widget.chatRoom.chatRoomId}",
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            AutocompleteLabel<User>(
              key: const Key('userDropDown'),
              label: _localizations?.chatPartner ?? 'Chat Partner',
              initialValue: _selectedUser,
              optionsBuilder: (TextEditingValue textEditingValue) {
                _userBloc.add(
                  GetDataEvent(
                    () => context.read<RestClient>().getUser(
                      searchString: textEditingValue.text,
                      limit: 3,
                      isForDropDown: true,
                      loginOnly: true,
                    ),
                  ),
                );
                return Future.delayed(const Duration(milliseconds: 150), () {
                  return (_userBloc.state.data as Users).users;
                });
              },
              displayStringForOption: (User u) =>
                  " ${u.firstName} ${u.lastName}",
              onSelected: (User? newValue) {
                _selectedUser = newValue;
              },
              validator: (value) =>
                  _nameController.text.isEmpty && value == null
                  ? _localizations?.chatFieldRequired ?? 'Field required'
                  : null,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              key: const Key('update'),
              child: Text(
                widget.chatRoom.chatRoomId.isEmpty
                    ? _localizations?.chatCreate ?? 'Create'
                    : _localizations?.chatUpdate ?? 'Update',
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate() && !loading) {
                  context.read<ChatRoomBloc>().add(
                    ChatRoomUpdate(
                      widget.chatRoom.copyWith(
                        chatRoomName: _nameController.text.isEmpty
                            ? null
                            : _nameController.text,
                        isPrivate: true,
                        members: [
                          ChatRoomMember(user: _selectedUser!, isActive: true),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
