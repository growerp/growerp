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

import 'package:growerp_core/l10n/generated/core_localizations.dart';

import '../../domains.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeIpForm extends StatefulWidget {
  const ChangeIpForm({super.key});

  @override
  State<ChangeIpForm> createState() => _ChangeIpFormState();
}

class _ChangeIpFormState extends State<ChangeIpForm> {
  final _formKey = GlobalKey<FormState>();
  CoreLocalizations? _localizations;

  @override
  Widget build(BuildContext context) {
    _localizations = CoreLocalizations.of(context);
    String ip = '', companyPartyId = '', chat = '';
    return Center(
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        title: Text(
          _localizations!.enterBackendUrl,
          textAlign: TextAlign.center,
        ),
        content: Form(
          key: _formKey,
          child: SizedBox(
            height: 300,
            child: Column(
              children: <Widget>[
                TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: _localizations!.backendServer,
                  ),
                  validator: (value) =>
                      value == null ? _localizations!.fieldRequired : null,
                  onChanged: (value) {
                    setState(() {
                      ip = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: _localizations!.chatServer,
                  ),
                  validator: (value) =>
                      value == null ? _localizations!.fieldRequired : null,
                  onChanged: (value) {
                    setState(() {
                      chat = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: _localizations!.companyPartyId,
                  ),
                  onChanged: (value) {
                    companyPartyId = value;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton(
                      child: Text(_localizations!.cancel),
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLoad());
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: OutlinedButton(
                        child: Text(_localizations!.ok),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (!ip.startsWith('https://')) {
                              ip = 'https://$ip';
                            }
                            if (!ip.endsWith('/')) ip = '$ip/';
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setString('ip', ip);
                            if (!chat.startsWith('wss://')) {
                              chat = 'wss://$chat';
                            }
                            if (!chat.endsWith('/')) chat = '$chat/';
                            await prefs.setString('chat', chat);
                            if (companyPartyId.isNotEmpty) {
                              await prefs.setString(
                                'companyPartyId',
                                companyPartyId,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
