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
import '../models/@models.dart';
import '../blocs/@blocs.dart';
import '../routing_constants.dart';
import 'changePw_form.dart';
import '../helper_functions.dart';

/// LoginForm: login or company selection depending on [Authenticate.company.partyId]
///
///  shows dual form depending on Auth.company.partyId:
///   when null show company selection and returns to homescreen
///   when present show customer login user/password
class LoginForm extends StatelessWidget {
  final String message;
  const LoginForm([this.message]);
  @override
  Widget build(BuildContext context) {
    Authenticate authenticate;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthUnauthenticated) authenticate = state.authenticate;
      return Scaffold(
        appBar: AppBar(
          title: Text(authenticate?.company?.partyId == null
              ? 'Select company'
              : 'Login to: ${authenticate?.company?.name}'),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.home),
                onPressed: () => Navigator.pushNamed(context, HomeRoute)),
          ],
        ),
        body: BlocProvider(
          create: (context) => LoginBloc(repos: context.repository<Object>())
            ..add(LoadLogin(authenticate)),
          child: LoginHeader(message),
        ),
      );
    });
  }
}

class LoginHeader extends StatefulWidget {
  final String message;
  const LoginHeader(this.message);
  @override
  State<LoginHeader> createState() => _LoginHeaderState(message);
}

class _LoginHeaderState extends State<LoginHeader> {
  final String message;
  final _formKey = GlobalKey<FormState>();
  Authenticate authenticate;
  bool _obscureText = true;
  String companyPartyId;
  String companyName;
  List<Company> companies;
  Company _companySelected;
  _LoginHeaderState(this.message);

  @override
  void initState() {
    Future<Null>.delayed(Duration(milliseconds: 0), () {
      if (message != null)
        HelperFunctions.showMessage(context, '$message', Colors.green);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(listener: (context, state) {
            if (state is AuthAuthenticated) Navigator.pop(context, true);
            if (state is AuthProblem) {
              HelperFunctions.showMessage(
                  context, '${state.errorMessage}', Colors.red);
            }
          }),
          BlocListener<LoginBloc, LoginState>(listener: (context, state) {
            if (state is LoginLoading && companyPartyId == null) {
              HelperFunctions.showMessage(
                  context, 'Loading login form...', Colors.green);
            }
            if (state is LogginInProgress) {
              HelperFunctions.showMessage(
                  context, 'Logging in....', Colors.green);
            }
            if (state is LoginError) {
              HelperFunctions.showMessage(
                  context, '${state.errorMessage}', Colors.red);
            }
            if (state is LoginChangePw) {
              Navigator.pushNamed(context, ChangePwRoute,
                  arguments: ChangePwArgs(state.username, state.password));
            }
            if (state is LoginOk) {
              BlocProvider.of<AuthBloc>(context)
                  .add(LoggedIn(authenticate: state.authenticate));
            }
          }),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
          if (state is AuthUnauthenticated) {
            authenticate = state.authenticate;
            companyPartyId = authenticate?.company?.partyId;
            companyName = authenticate?.company?.name;
          }
          return BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
            if (state is LoginLoading)
              return Center(child: CircularProgressIndicator());
            if (state is LoginLoaded) {
              companies = state?.companies;
              _companySelected = companies != null
                  ? companies[0]
                  : Company(partyId: companyPartyId);
            }
            if (companyPartyId == null) {
              return _changeEcommerceCompany();
            } else {
              return _loginToCurrentCompany(state);
            }
          });
        }));
  }

  Widget _changeEcommerceCompany() {
    return Center(
        child: Container(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(height: 40),
                  Container(
                    width: 400,
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      border: Border.all(
                          color: Colors.grey,
                          style: BorderStyle.solid,
                          width: 0.80),
                    ),
                    child: DropdownButton(
                      key: ValueKey('drop_down'),
                      underline: SizedBox(), // remove underline
                      hint: Text('Company'),
                      value: _companySelected,
                      items: companies?.map((item) {
                        return DropdownMenuItem<Company>(
                          child: Text(item?.name ?? 'Company??'),
                          value: item,
                        );
                      })?.toList(),
                      onChanged: (Company newValue) {
                        authenticate.company = newValue;
                        BlocProvider.of<AuthBloc>(context)
                            .add(UpdateAuth(authenticate));
                        Navigator.pushNamedAndRemoveUntil(
                            context, HomeRoute, ModalRoute.withName(HomeRoute),
                            arguments:
                                FormArguments("Ecommerce company changed!"));
                      },
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
            )));
  }

  Widget _loginToCurrentCompany(state) {
    final _usernameController = TextEditingController()
      ..text = authenticate?.user?.name != null
          ? authenticate.user.name
          : kReleaseMode
              ? ''
              : 'admin@growerp.com';
    final _passwordController = TextEditingController()
      ..text = kReleaseMode ? '' : 'qqqqqq9!';
    return Center(
        child: Container(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(height: 40),
                  SizedBox(height: 20),
                  TextFormField(
                    autofocus: true,
                    key: Key('username'),
                    decoration: InputDecoration(labelText: 'Username'),
                    controller: _usernameController,
                    validator: (value) {
                      if (value.isEmpty)
                        return 'Please enter username or email?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                      key: Key('password'),
                      validator: (value) {
                        if (value.isEmpty) return 'Please enter your password?';
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
                  RaisedButton(
                      child: Text('Login'),
                      onPressed: () {
                        if (_formKey.currentState.validate() &&
                            state is! LogginInProgress)
                          BlocProvider.of<LoginBloc>(context).add(
                              LoginButtonPressed(
                                  company: authenticate.company,
                                  username: _usernameController.text,
                                  password: _passwordController.text));
                      }),
                  SizedBox(height: 30),
                  GestureDetector(
                    child: Text('register new account'),
                    onTap: () async {
                      final dynamic result =
                          await Navigator.pushNamed(context, RegisterRoute);
                      HelperFunctions.showMessage(
                          context, '$result', Colors.green);
                    },
                  ),
                  SizedBox(height: 30),
                  GestureDetector(
                      child: Text('forgot/change password?'),
                      onTap: () async {
                        final String username = await _sendResetPasswordDialog(
                            context,
                            authenticate?.user?.name == null || kReleaseMode
                                ? 'admin@growerp.com'
                                : authenticate?.user?.name);
                        if (username != null) {
                          BlocProvider.of<AuthBloc>(context)
                              .add(ResetPassword(username: username));
                          HelperFunctions.showMessage(
                              context,
                              'An email with password has been '
                              'send to $username',
                              Colors.green);
                        }
                      }),
                  Container(
                    child: state is LogginInProgress
                        ? CircularProgressIndicator()
                        : null,
                  ),
                ],
              ),
            )));
  }
}

_sendResetPasswordDialog(BuildContext context, String username) async {
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
        content: Row(children: <Widget>[
          Expanded(
              child: TextFormField(
                  initialValue: username,
                  autofocus: true,
                  decoration: new InputDecoration(labelText: 'Email:'),
                  onChanged: (value) {
                    username = value;
                  }))
        ]),
        actions: <Widget>[
          FlatButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
          FlatButton(
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
