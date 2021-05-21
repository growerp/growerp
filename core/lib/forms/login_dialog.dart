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

import 'package:core/forms/register_dialog.dart';
import 'package:core/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:models/@models.dart';
import '../blocs/@blocs.dart';
import 'changePw_form.dart';
import '../helper_functions.dart';

class LoginDialog extends StatelessWidget {
  final FormArguments formArguments;
  const LoginDialog({Key? key, required this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? message = formArguments.message;
    var repos = context.read<Object>();
    late Authenticate authenticate;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthUnauthenticated) authenticate = state.authenticate;
      return BlocProvider(
        create: (context) =>
            LoginBloc(repos: repos)..add(LoadLogin(authenticate)),
        child: LoginHeader(message),
      );
    });
  }
}

class LoginHeader extends StatefulWidget {
  final String? message;
  const LoginHeader(this.message);
  @override
  State<LoginHeader> createState() => _LoginHeaderState(message);
}

class _LoginHeaderState extends State<LoginHeader> {
  final String? message;
  final _formKey = GlobalKey<FormState>();
  late Authenticate authenticate;
  bool _obscureText = true;
  String? companyPartyId;
  String? companyName;
  List<Company>? companies;
  Company? _companySelected;
  _LoginHeaderState(this.message);

  @override
  void initState() {
    Future<Null>.delayed(Duration(milliseconds: 0), () {
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
            if (state is LogginInProgress) {
              HelperFunctions.showMessage(
                  context, 'Logging in....', Colors.green);
            }
            if (state is LoginError) {
              HelperFunctions.showMessage(
                  context, '${state.errorMessage}', Colors.red);
            }
            if (state is LoginChangePw) {
              Navigator.pushNamed(context, '/changepw',
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
            companyPartyId = authenticate.company!.partyId;
            companyName = authenticate.company!.name;
          }
          return BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
            if (state is LoginLoading || state is LoginInitial)
              return Center(child: CircularProgressIndicator());
            if (state is LoginLoaded) {
              companies = state.companies;
              _companySelected = companies != null
                  ? companies![0]
                  : Company(partyId: companyPartyId);
            }
            Widget loginType;
            if (companyPartyId == null) {
              loginType = _changeEcommerceCompany();
            } else {
              loginType = _loginToCurrentCompany(state);
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
        }));
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
                authenticate.copyWith(company: newValue);
                BlocProvider.of<AuthBloc>(context)
                    .add(UpdateAuth(authenticate));
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

  Widget _loginToCurrentCompany(state) {
    final _usernameController = TextEditingController()
      ..text = authenticate.user?.name != null
          ? authenticate.user!.name!
          : kReleaseMode
              ? ''
              : 'admin@growerp.com';
    final _passwordController = TextEditingController()
      ..text = kReleaseMode ? '' : 'qqqqqq9!';
    return Container(
        padding: EdgeInsets.all(20),
        width: 400,
        height: 500,
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              SizedBox(height: 20),
              Center(
                  child: Text("Login with Existing user name",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold))),
              SizedBox(height: 20),
              TextFormField(
                autofocus: true,
                key: Key('username'),
                decoration: InputDecoration(labelText: 'Username'),
                controller: _usernameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter username or email?';
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
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
              ElevatedButton(
                  key: Key('login'),
                  child: Text('Login'),
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        state is! LogginInProgress)
                      BlocProvider.of<LoginBloc>(context).add(
                          LoginButtonPressed(
                              company: authenticate.company,
                              username: _usernameController.text,
                              password: _passwordController.text));
                  }),
              SizedBox(height: 20),
              ElevatedButton(
                  key: Key('cancel'),
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              SizedBox(height: 30),
              Center(
                  child: GestureDetector(
                      child: Text('forgot/change password?'),
                      onTap: () async {
                        final String username = await _sendResetPasswordDialog(
                            context,
                            authenticate.user!.name == null || kReleaseMode
                                ? 'admin@growerp.com'
                                : authenticate.user!.name);
                        if (username.isNotEmpty) {
                          BlocProvider.of<AuthBloc>(context)
                              .add(ResetPassword(username: username));
                          HelperFunctions.showMessage(
                              context,
                              'An email with password has been '
                              'send to $username',
                              Colors.green);
                        }
                      })),
              SizedBox(height: 30),
              Center(
                  child: GestureDetector(
                      child: Text('register new account for\n$companyName'),
                      onTap: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return RegisterDialog(
                                  formArguments: FormArguments());
                            });
                      })),
              Container(
                child: state is LogginInProgress ? LoadingIndicator() : null,
              ),
            ],
          ),
        ));
  }
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
          ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(null);
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
