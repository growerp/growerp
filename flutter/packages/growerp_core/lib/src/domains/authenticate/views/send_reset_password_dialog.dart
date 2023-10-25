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
import '../../domains.dart';
import '../../common/functions/helper_functions.dart';

class SendResetPasswordDialog extends StatefulWidget {
  const SendResetPasswordDialog(this.username, {super.key});

  final String username;

  @override
  State<SendResetPasswordDialog> createState() =>
      _SendResetPasswordDialogState();
}

class _SendResetPasswordDialogState extends State<SendResetPasswordDialog> {
  late String username;
  late AuthBloc _authBloc;
  final _formKeyResetPassword = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    username = widget.username;
    _authBloc = context.read<AuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      switch (state.status) {
        case AuthStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        case AuthStatus.unAuthenticated:
          Navigator.pop(context, state.message);
        default:
          HelperFunctions.showMessage(context, state.message, Colors.green);
      }
    }, builder: (context, state) {
      if (state.status == AuthStatus.loading) {
        return const LoadingIndicator();
      } else {
        return Scaffold(
            backgroundColor: Colors.transparent,
            body: Dialog(
                insetPadding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                    height: 300,
                    context: context,
                    title: "Send new Password by email",
                    child: Form(
                      key: _formKeyResetPassword,
                      child: SingleChildScrollView(
                          key: const Key('listView'),
                          child: Column(children: [
                            const SizedBox(height: 20),
                            TextFormField(
                                initialValue: widget.username,
                                autofocus: true,
                                decoration:
                                    const InputDecoration(labelText: 'Email:'),
                                onChanged: (value) {
                                  username = value;
                                }),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              child: const Text('Ok'),
                              onPressed: () {
                                _authBloc
                                    .add(AuthResetPassword(username: username));
                              },
                            ),
                          ])),
                    ))));
      }
    });
  }
}
