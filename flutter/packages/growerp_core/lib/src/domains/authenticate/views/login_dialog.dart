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
import 'package:growerp_models/growerp_models.dart';

import '../../../domains/domains.dart';
import '../../../l10n/generated/core_localizations.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  LoginDialogState createState() => LoginDialogState();
}

class LoginDialogState extends State<LoginDialog> {
  final _loginFormKey = GlobalKey<FormState>();
  final _moreInfoFormKey = GlobalKey<FormState>();
  late Authenticate authenticate;
  List<Company>? companies;
  String? oldPassword;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  final _changePasswordFormKey = GlobalKey<FormState>();
  final _password3Controller = TextEditingController();
  final _password4Controller = TextEditingController();
  late bool _obscureText;
  late bool _obscureText3;
  late bool _obscureText4;
  late AuthBloc _authBloc;
  late Currency _currencySelected;
  late bool _demoData;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    authenticate = _authBloc.state.authenticate!;
    _usernameController.text = authenticate.user?.loginName ??
        (kReleaseMode ? '' : 'test@example.com');
    _currencySelected = currencies[1];
    _demoData = kReleaseMode ? false : true;
    if (!kReleaseMode) {
      _passwordController.text = 'qqqqqq9!';
      _companyController.text = 'Main Company';
    }
    _obscureText = true;
    _obscureText3 = true;
    _obscureText4 = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        Navigator.of(context).pop();
      }
    }, builder: (context, state) {
      if (state.status == AuthStatus.loading) return const LoadingIndicator();
      var furtherAction = state.authenticate!.apiKey;
      return Scaffold(
          backgroundColor: Colors.transparent,
          body: Dialog(
              insetPadding: const EdgeInsets.all(10),
              child: furtherAction == 'moreInfo'
                  ? moreInfoForm(state.authenticate!)
                  : furtherAction == 'passwordChange'
                      ? changePasswordForm(
                          _usernameController.text, _passwordController.text)
                      : loginForm()));
    });
  }

  Widget changePasswordForm(String username, String oldPassword) {
    return popUp(
        height: 500,
        context: context,
        title: "Create New Password",
        child: Form(
          key: _changePasswordFormKey,
          child: Column(children: <Widget>[
            const SizedBox(height: 40),
            Text("username: $username"),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key("password1"),
              autofocus: true,
              controller: _password3Controller,
              obscureText: _obscureText3,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters, including alpha, number '
                    '&\nspecial character, no previous password.',
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText3 = !_obscureText3;
                    });
                  },
                  child: Icon(
                      _obscureText3 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter first password?';
                final regExpRequire =
                    RegExp(r'^(?=.*[0-9])(?=.*[a-zA-Z])(?=.*[!@#$%^&+=]).{8,}');
                if (!regExpRequire.hasMatch(value)) {
                  return 'At least 8 characters, including alpha, number & special character.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key("password2"),
              obscureText: _obscureText4,
              decoration: InputDecoration(
                labelText: 'Verify Password',
                helperText: 'Enter the new password again.',
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText4 = !_obscureText4;
                    });
                  },
                  child: Icon(
                      _obscureText4 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              controller: _password4Controller,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Enter password again to verify?';
                }
                if (value != _password4Controller.text) {
                  return 'Password is not matching';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
                child: const Text('Submit new Password'),
                onPressed: () {
                  if (_changePasswordFormKey.currentState!.validate()) {
                    _authBloc.add(
                      AuthChangePassword(
                        username,
                        oldPassword,
                        _password4Controller.text,
                      ),
                    );
                  }
                }),
          ]),
        ));
  }

  Widget moreInfoForm(Authenticate authenticate) {
    var user = authenticate.user;
    return popUp(
        height: user?.userGroup == UserGroup.admin ? 450 : 350,
        context: context,
        title: 'Complete your registration',
        closeButton: false,
        child: Form(
            key: _moreInfoFormKey,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                key: const Key('listView'),
                child: Column(key: const Key('moreInfo'), children: <Widget>[
                  Column(children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome!",
                      textAlign: TextAlign.center,
                    ),
                    Text("${user?.lastName}, ${user?.firstName}"),
                    if (user?.userGroup == UserGroup.admin)
                      const Text(
                          "please enter both the company name\nand currency for the new company"),
                    if (user?.userGroup != UserGroup.admin)
                      const Text(
                          "please enter optionally a company name you work for."),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('companyName'),
                      decoration: const InputDecoration(
                          labelText: 'Business Company name'),
                      controller: _companyController,
                      validator: (value) {
                        if (user?.userGroup == UserGroup.admin &&
                            value!.isEmpty) {
                          return 'Please enter business name("Private" for Private person)';
                        }
                        return null;
                      },
                    ),
                    if (user?.userGroup == UserGroup.admin)
                      const SizedBox(height: 10),
                    if (user?.userGroup == UserGroup.admin)
                      DropdownButtonFormField<Currency>(
                        key: const Key('currency'),
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                        hint: const Text('Currency'),
                        value: _currencySelected,
                        validator: (value) =>
                            value == null ? 'Currency field required!' : null,
                        items: currencies.map((item) {
                          return DropdownMenuItem<Currency>(
                              value: item, child: Text(item.description!));
                        }).toList(),
                        onChanged: (Currency? newValue) {
                          setState(() {
                            _currencySelected = newValue!;
                          });
                        },
                        isExpanded: true,
                      ),
                    const SizedBox(height: 10),
                    if (user?.userGroup == UserGroup.admin)
                      InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'DemoData'),
                          child: CheckboxListTile(
                              key: const Key('demoData'),
                              title: const Text("Generate demo data"),
                              value: _demoData,
                              onChanged: (bool? value) {
                                setState(() {
                                  _demoData = value!;
                                });
                              })),
                    const SizedBox(height: 10),
                    OutlinedButton(
                        key: const Key('continue'),
                        child: const Text('Continue'),
                        onPressed: () {
                          if (_moreInfoFormKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(AuthLogin(
                                user!.loginName!,
                                authenticate.moquiSessionToken!,
                                extraInfo: true,
                                companyName: _companyController.text,
                                currency: _currencySelected,
                                demoData: _demoData));
                          }
                        })
                  ])
                ]))));
  }

  Widget loginForm() {
    return popUp(
        height: 350,
        context: context,
        title: CoreLocalizations.of(context)!.loginWithExistingUserName,
        child: Form(
            key: _loginFormKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              key: const Key('listView'),
              child: Column(children: <Widget>[
                TextFormField(
                  autofocus: _usernameController.text.isEmpty,
                  key: const Key('username'),
                  decoration:
                      const InputDecoration(labelText: 'Username/Email'),
                  controller: _usernameController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter username or email?';
                    }
                    return null;
                  },
                ),
                TextFormField(
                    autofocus: _usernameController.text.isNotEmpty,
                    key: const Key('password'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your password?';
                      }
                      return null;
                    },
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        child: Icon(_obscureText
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    )),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          key: const Key('login'),
                          child: const Text('Login'),
                          onPressed: () {
                            if (_loginFormKey.currentState!.validate()) {
                              _authBloc.add(AuthLogin(_usernameController.text,
                                  _passwordController.text));
                            }
                          }))
                ]),
                const SizedBox(height: 20),
                Center(
                    child: GestureDetector(
                        child: const Text('forgot/change password?'),
                        onTap: () async {
                          String username = authenticate.user?.loginName ??
                              (kReleaseMode ? '' : 'test@example.com');
                          await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                    value: _authBloc,
                                    child: SendResetPasswordDialog(username));
                              });
                        })),
              ]),
            )));
  }
}
