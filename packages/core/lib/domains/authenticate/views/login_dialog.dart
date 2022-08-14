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

import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:core/domains/domains.dart';

class LoginDialog extends StatefulWidget {
  final String? message;
  const LoginDialog([this.message]);
  @override
  State<LoginDialog> createState() => _LoginHeaderState(message);
}

class _LoginHeaderState extends State<LoginDialog> {
  final String? message;
  final _formKey = GlobalKey<FormState>();
  late Authenticate authenticate;
  bool _obscureText = true;
  String? companyPartyId;
  String? companyName;
  List<Company>? companies;
  Company? _companySelected;
  _LoginHeaderState(this.message);
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    Future<Null>.delayed(Duration(milliseconds: 0), () {
      HelperFunctions.showMessage(context, '$message', Colors.green);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      switch (state.status) {
        case AuthStatus.authenticated:
          Navigator.of(context).pop(state.authenticate);
          break;
        case AuthStatus.passwordChange:
          Navigator.pushNamed(context, '/changePw',
              arguments: ChangePwArgs(
                  _usernameController.text, _passwordController.text));
          break;
        case AuthStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
      }
    }, builder: (context, state) {
      if (state.status == AuthStatus.loading) return LoadingIndicator();
      authenticate = state.authenticate!;
      companyPartyId = authenticate.company!.partyId;
      companyName = authenticate.company!.name;
      if (_usernameController.text.isEmpty)
        _usernameController.text = authenticate.user?.loginName != null
            ? authenticate.user!.loginName!
            : kReleaseMode
                ? ''
                : 'test@example.com';
      if (_passwordController.text.isEmpty && !kReleaseMode)
        _passwordController.text = 'qqqqqq9!';
      Widget loginType;
      if (companyPartyId == null) {
        loginType = _changeEcommerceCompany();
      } else {
        loginType = _loginToCurrentCompany(state, context);
      }
      return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Builder(
                  builder: (context) => GestureDetector(
                      onTap: () {},
                      child: Dialog(
                          insetPadding: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: loginType)))));
    });
  }

  Widget _changeEcommerceCompany() {
    return Container(
        width: 400,
        height: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: DropdownButton(
              key: ValueKey('drop_down'),
              underline: SizedBox(), // remove underline
              hint: Text('Company'),
              value: _companySelected,
              items: companies?.map((item) {
                return DropdownMenuItem<Company>(
                  child: Text(item.name ?? 'Company??'),
                  value: item,
                );
              }).toList(),
              onChanged: (Company? newValue) {
                context.read<AuthBloc>().add(AuthUpdateCompany(newValue!));
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', ModalRoute.withName('/'),
                    arguments:
                        FormArguments(message: "Ecommerce company changed!"));
              },
              isExpanded: true,
            ),
          ),
        ));
  }

  Widget _loginToCurrentCompany(AuthState state, BuildContext context) {
    return PopUp(
        context: context,
        title: "Login with Existing user name",
        child: Form(
            key: _formKey,
            child: ListView(children: <Widget>[
              SizedBox(height: 20),
              TextFormField(
                autofocus: _usernameController.text.isEmpty,
                key: Key('username'),
                decoration: InputDecoration(labelText: 'Username/Email'),
                controller: _usernameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter username or email?';
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                  autofocus: _usernameController.text.isNotEmpty,
                  key: Key('password'),
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
              SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: ElevatedButton(
                        key: Key('login'),
                        child: Text('Login'),
                        onPressed: () {
                          if (_formKey.currentState!.validate())
                            context.read<AuthBloc>().add(AuthLogin(
                                authenticate.company,
                                _usernameController.text,
                                _passwordController.text));
                        }))
              ]),
              SizedBox(height: 30),
              Center(
                  child: GestureDetector(
                      child: Text('forgot/change password?'),
                      onTap: () async {
                        String username = authenticate.user?.loginName ??
                            (kReleaseMode ? '' : 'test@example.com');
                        username =
                            await _sendResetPasswordDialog(context, username);
                        if (username.isNotEmpty) {
                          context
                              .read<AuthBloc>()
                              .add(AuthResetPassword(username: username));
                          HelperFunctions.showMessage(
                              context,
                              'An email with password has been '
                              'send to $username',
                              Colors.green);
                        }
                      })),
            ])));
  }

  _sendResetPasswordDialog(BuildContext context, String? username) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          title: Text(
              'Email you registered with?\nWe will send you a reset password',
              textAlign: TextAlign.center),
          content: TextFormField(
              initialValue: username,
              autofocus: true,
              decoration: new InputDecoration(labelText: 'Email:'),
              onChanged: (value) {
                username = value;
              }),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop('');
              },
            ),
            ElevatedButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(username);
              },
            ),
          ],
        );
      },
    );
  }

  Future<Object>? PopUpWait(
      {required BuildContext context,
      required Widget child,
      String title = '',
      double height = 400}) {
    PopUp(context: context, child: child);
    return Future.value(Object());
  }
}

Widget PopUp({
  required BuildContext context,
  required Widget child,
  String title = '',
  double height = 400,
  double width = 400,
}) {
  return Stack(clipBehavior: Clip.none, children: [
    Container(
        width: width,
        height: height,
        child: Column(children: [
          Container(
              height: 50,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  )),
              child: Center(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)))),
          Expanded(child: Padding(padding: EdgeInsets.all(20), child: child)),
        ])),
    Positioned(top: 10, right: 10, child: DialogCloseButton())
  ]);
}
