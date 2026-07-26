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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';
import '../../domains.dart';

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
  final _usernameController = TextEditingController();
  CoreLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _usernameController.text =
        _authBloc.state.authenticate?.user?.loginName ??
        (kReleaseMode ? '' : 'test@example.com');
  }

  @override
  Widget build(BuildContext context) {
    _localizations = CoreLocalizations.of(context);
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unAuthenticated) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (state.status == AuthStatus.loading) {
          return const LoadingIndicator();
        } else {
          return Dialog(
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: popUp(
              height: 300,
              context: context,
              title: _localizations!.sendNewPassword,
              child: Form(
                key: _formKeyResetPassword,
                child: SingleChildScrollView(
                  key: const Key('listView'),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('resetEmail'),
                        controller: _usernameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: _localizations!.email,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        key: const Key('resetPasswordOk'),
                        child: Text(_localizations!.ok),
                        onPressed: () {
                          _authBloc.add(
                            AuthResetPassword(
                              username: _usernameController.text,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
