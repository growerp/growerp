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
import 'package:flutter/foundation.dart';
import '../blocs/@blocs.dart';

class ChangePwArgs {
  final String username;
  final String oldPassword;
  const ChangePwArgs(
    this.username,
    this.oldPassword,
  );
}

class ChangePwForm extends StatelessWidget {
  final ChangePwArgs changePwArgs;
  const ChangePwForm({this.changePwArgs});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.home),
              onPressed: () =>
                  BlocProvider.of<AuthBloc>(context).add(LoadAuth())),
        ],
      ),
      body: BlocProvider(
        create: (context) {
          return ChangePwBloc(repos: context.repository<Object>());
        },
        child: ChangePwEntry(
          username: changePwArgs.username,
          oldPassword: changePwArgs.oldPassword,
        ),
      ),
    );
  }
}

class ChangePwEntry extends StatefulWidget {
  final String username;
  final String oldPassword;

  const ChangePwEntry({Key key, this.username, this.oldPassword})
      : super(key: key);
  @override
  State<ChangePwEntry> createState() =>
      _ChangePwEntryState(username, oldPassword);
}

class _ChangePwEntryState extends State<ChangePwEntry> {
  final String username;
  final String oldPassword;
  final _formKey = GlobalKey<FormState>();
  bool _obscureText1 = true;
  bool _obscureText2 = true;
  final _password1Controller = TextEditingController();
  final _password2Controller = TextEditingController();

  _ChangePwEntryState(this.username, this.oldPassword);

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChangePwBloc, ChangePwState>(
        listener: (context, state) {
      if (state is ChangePwFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${state.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (state is ChangePwOk) {
        Navigator.of(context).pop("Password successfully changed");
      }
    }, child:
            BlocBuilder<ChangePwBloc, ChangePwState>(builder: (context, state) {
      return Scaffold(
          body: Center(
              child: SizedBox(
                  width: 400,
                  child: Form(
                    key: _formKey,
                    child: Column(children: <Widget>[
                      SizedBox(height: 40),
                      Text('You entered the correct temporary password\n'),
                      Text('Now enter a new password.\n'),
                      SizedBox(height: 20),
                      Text("username: $username"),
                      SizedBox(height: 20),
                      TextFormField(
                        key: Key("password1"),
                        autofocus: true,
                        controller: _password1Controller,
                        obscureText: _obscureText1,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText:
                              'At least 8 characters, including alpha, number & special character.',
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureText1 = !_obscureText1;
                              });
                            },
                            child: Icon(_obscureText1
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                        validator: (value) {
                          if (value.isEmpty)
                            return 'Please enter first password?';
                          final regExpRequire = RegExp(
                              r'^(?=.*[0-9])(?=.*[a-zA-Z])(?=.*[!@#$%^&+=]).{8,}');
                          if (!regExpRequire.hasMatch(value))
                            return 'At least 8 characters, including alpha, number & special character.';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        key: Key("password2"),
                        obscureText: _obscureText2,
                        decoration: InputDecoration(
                          labelText: 'Verify Password',
                          helperText: 'Enter the new password again.',
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureText2 = !_obscureText2;
                              });
                            },
                            child: Icon(_obscureText2
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                        controller: _password2Controller,
                        validator: (value) {
                          if (value.isEmpty)
                            return 'Enter password again to verify?';
                          if (value != _password1Controller.text)
                            return 'Password is not matching';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      RaisedButton(
                          child: Text('Submit new Password'),
                          onPressed: () {
                            if (_formKey.currentState.validate() &&
                                state is ChangePwInitial)
                              BlocProvider.of<ChangePwBloc>(context).add(
                                ChangePwButtonPressed(
                                  username: username,
                                  oldPassword: oldPassword,
                                  newPassword: _password1Controller.text,
                                ),
                              );
                          }),
                    ]),
                  ))));
    }));
  }
}
