// ignore_for_file: curly_braces_in_flow_control_structures

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
import 'package:responsive_framework/responsive_framework.dart';
import '../../domains.dart';

class RegisterUserDialog extends StatefulWidget {
  const RegisterUserDialog(this.admin, {super.key});

  final bool admin;

  @override
  State<RegisterUserDialog> createState() => _RegisterUserDialogState();
}

class _RegisterUserDialogState extends State<RegisterUserDialog> {
  final _registerFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  late AuthBloc _authBloc;
  Company? _presetCompany;
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = kReleaseMode ? '' : 'John';
    _lastNameController.text = kReleaseMode ? '' : 'Doe';
    _authBloc = context.read<AuthBloc>();
    _emailController.text = _authBloc.state.authenticate?.user?.loginName ??
        (kReleaseMode ? '' : 'test@example.com');
    _presetCompany = context.read<Company?>();
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      if (state.status == AuthStatus.unAuthenticated) {
        Navigator.pop(context);
      }
    }, builder: (context, state) {
      if (state.status == AuthStatus.loading) {
        return const LoadingIndicator();
      } else {
        return Scaffold(
            backgroundColor: Colors.transparent,
            body: Dialog(
                insetPadding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                  context: context,
                  title: "Registration",
                  height: isPhone ? 350 : 300,
                  child: _registerForm(_authBloc.state.authenticate!),
                )));
      }
    });
  }

  Widget _registerForm(Authenticate authenticate) {
    return Form(
        key: _registerFormKey,
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            key: const Key('listView'),
            child: Column(children: <Widget>[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('firstName'),
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                      controller: _firstNameController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your first name?';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      key: const Key('lastName'),
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      controller: _lastNameController,
                      validator: (value) {
                        if (value!.isEmpty)
                          return 'Please enter your last name?';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('A temporary password will be send by email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                  )),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('email'),
                decoration: const InputDecoration(labelText: 'Email address'),
                controller: _emailController,
                validator: (String? value) {
                  if (value!.isEmpty) return 'Please enter Email address?';
                  if (!RegExp(
                          r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                      .hasMatch(value)) {
                    return 'This is not a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              OutlinedButton(
                  key: const Key('newUserButton'),
                  child: const Text('Register'),
                  onPressed: () async {
                    if (_registerFormKey.currentState!.validate()) {
                      _authBloc.add(AuthRegister(User(
                        company: _presetCompany ??
                            Company(partyId: _selectedCompany?.partyId),
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        email: _emailController.text,
                      )));
                    }
                  }),
            ])));
  }
}
