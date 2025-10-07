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
                        controller: _usernameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: _localizations!.email,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
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
