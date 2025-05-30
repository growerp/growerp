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

  @override
  Widget build(BuildContext context) {
    String ip = '', companyPartyId = '', chat = '';
    return Center(
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
        title: const Text(
            'Enter a backend && chat url in the form of: xxx.yyy.zzz',
            textAlign: TextAlign.center),
        content: Form(
            key: _formKey,
            child: SizedBox(
                height: 300,
                child: Column(children: <Widget>[
                  TextFormField(
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: 'Backend server:'),
                      validator: (value) =>
                          value == null ? 'field required!' : null,
                      onChanged: (value) {
                        setState(() {
                          ip = value;
                        });
                      }),
                  const SizedBox(height: 10),
                  TextFormField(
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: 'Chat server:'),
                      validator: (value) =>
                          value == null ? 'field required!' : null,
                      onChanged: (value) {
                        setState(() {
                          chat = value;
                        });
                      }),
                  const SizedBox(height: 10),
                  TextFormField(
                      autofocus: true,
                      decoration: const InputDecoration(
                          labelText: 'partyId of main company:'),
                      onChanged: (value) {
                        companyPartyId = value;
                      }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      OutlinedButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthLoad());
                        },
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: OutlinedButton(
                            child: const Text('Ok'),
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
                                      'companyPartyId', companyPartyId);
                                }
                              }
                            }),
                      )
                    ],
                  ),
                ]))),
      ),
    );
  }
}
