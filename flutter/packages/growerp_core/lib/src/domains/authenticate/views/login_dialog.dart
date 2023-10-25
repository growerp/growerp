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
import '../../common/functions/helper_functions.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginHeaderState();
}

class _LoginHeaderState extends State<LoginDialog> {
  final _loginFormKey = GlobalKey<FormState>();
  late Authenticate authenticate;
  bool _obscureText = true;
  String? companyPartyId;
  String? companyName;
  List<Company>? companies;
  Company? _companySelected;
  String? oldPassword;
  String? username;
  _LoginHeaderState();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginFormKey1 = GlobalKey<FormState>();
  final _password3Controller = TextEditingController();
  final _password4Controller = TextEditingController();
  bool _obscureText3 = true;
  bool _obscureText4 = true;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      switch (state.status) {
        case AuthStatus.authenticated:
          Navigator.pop(context, state.message);
          break;
        case AuthStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
      }
    }, builder: (context, state) {
      if (state.status == AuthStatus.loading) return const LoadingIndicator();
      if (state.status == AuthStatus.passwordChange) {
        username = _usernameController.text;
        oldPassword = _passwordController.text;
      }
      authenticate = state.authenticate!;
      companyPartyId = authenticate.company!.partyId;
      companyName = authenticate.company!.name;
      if (_usernameController.text.isEmpty) {
        _usernameController.text = authenticate.user?.loginName != null
            ? authenticate.user!.loginName!
            : kReleaseMode
                ? ''
                : 'test@example.com';
      }
      if (_passwordController.text.isEmpty && !kReleaseMode) {
        _passwordController.text = 'qqqqqq9!';
      }
      Widget loginType;
      if (oldPassword != null && username != null) {
        loginType = _changePassword(username, oldPassword);
      } else if (companyPartyId == null) {
        loginType = _changeEcommerceCompany();
      } else {
        loginType = _loginToCurrentCompany();
      }
      return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Builder(
                  builder: (context) => GestureDetector(
                      onTap: () {},
                      child: Dialog(
                          insetPadding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: loginType)))));
    });
  }

  Widget _changePassword(String? username, String? oldPassword) {
    return popUp(
        height: 500,
        context: context,
        title: "Create New Password",
        child: Form(
          key: _loginFormKey1,
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
                if (value!.isEmpty) return 'Enter password again to verify?';
                if (value != _password4Controller.text) {
                  return 'Password is not matching';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                child: const Text('Submit new Password'),
                onPressed: () {
                  if (_loginFormKey1.currentState!.validate()) {
                    _authBloc.add(
                      AuthChangePassword(
                        username!,
                        oldPassword!,
                        _password4Controller.text,
                      ),
                    );
                  }
                }),
          ]),
        ));
  }

  Widget _changeEcommerceCompany() {
    final loginFormKey2 = GlobalKey<FormState>();
    return SizedBox(
        width: 400,
        height: 400,
        child: Form(
          key: loginFormKey2,
          child: SingleChildScrollView(
            child: DropdownButton(
              key: const ValueKey('drop_down'),
              underline: const SizedBox(), // remove underline
              hint: const Text('Company'),
              value: _companySelected,
              items: companies?.map((item) {
                return DropdownMenuItem<Company>(
                  value: item,
                  child: Text(item.name ?? 'Company??'),
                );
              }).toList(),
              onChanged: (Company? newValue) {},
/*                context.read<AuthBloc>().add(AuthUpdateCompany(newValue!));
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', ModalRoute.withName('/'),
                    arguments:
                        FormArguments(message: "Ecommerce company changed!"));
              },
*/
              isExpanded: true,
            ),
          ),
        ));
  }

  Widget _loginToCurrentCompany() {
    return popUp(
        height: 400,
        context: context,
        title: CoreLocalizations.of(context)!.loginWithExistingUserName,
        child: Form(
            key: _loginFormKey,
            child: Column(children: <Widget>[
              const SizedBox(height: 20),
              TextFormField(
                autofocus: _usernameController.text.isEmpty,
                key: const Key('username'),
                decoration: const InputDecoration(labelText: 'Username/Email'),
                controller: _usernameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter username or email?';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                  onFieldSubmitted: (_) {
                    if (_loginFormKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(AuthLogin(
                          _usernameController.text, _passwordController.text));
                    }
                  },
                  autofocus: _usernameController.text.isNotEmpty,
                  key: const Key('password'),
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter your password?';
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
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: ElevatedButton(
                        key: const Key('login'),
                        child: const Text('Login'),
                        onPressed: () {
                          if (_loginFormKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(AuthLogin(
                                _usernameController.text,
                                _passwordController.text));
                          }
                        }))
              ]),
              const SizedBox(height: 30),
              Center(
                  child: GestureDetector(
                      child: const Text('forgot/change password?'),
                      onTap: () async {
                        String username = authenticate.user?.loginName ??
                            (kReleaseMode ? '' : 'test@example.com');
                        var message = await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _authBloc,
                                  child: SendResetPasswordDialog(username));
                            });
                        if (message != null) {
                          await Future.delayed(
                              const Duration(milliseconds: 200),
                              () => _authBloc.add(AuthLastMessage(message)));
                        }
                      })),
            ])));
  }
}
