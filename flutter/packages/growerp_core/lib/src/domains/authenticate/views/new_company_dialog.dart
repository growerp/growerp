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
import '../../domains.dart';
import '../../common/functions/helper_functions.dart';

class NewCompanyDialog extends StatefulWidget {
  const NewCompanyDialog(this.admin, {super.key});

  final bool admin;

  @override
  State<NewCompanyDialog> createState() => _NewCompanyDialogState();
}

class _NewCompanyDialogState extends State<NewCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  late bool _demoData;
  late Currency _currencySelected;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _companyController.text = kReleaseMode ? '' : 'Demo company from John Doe';
    _firstNameController.text = kReleaseMode ? '' : 'John';
    _lastNameController.text = kReleaseMode ? '' : 'Doe';
    _emailController.text = kReleaseMode ? '' : 'test@example.com';
    _demoData = kReleaseMode ? false : true;
    _currencySelected = currencies[1];
    _authBloc = context.read<AuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      if (state.status == AuthStatus.failure) {
        HelperFunctions.showMessage(context, state.message, Colors.red);
      }
      if (state.status == AuthStatus.unAuthenticated) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green,
            seconds: 10);
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
                    child: _registerForm(_authBloc.state.authenticate!),
                    title: !widget.admin
                        ? "Enter a new customer for company\n "
                            "${_authBloc.state.authenticate!.company!.name}"
                        : "Enter a new company with admin",
                    height: 700,
                    width: 400)));
      }
    });
  }

  Widget _registerForm(Authenticate authenticate) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            key: const Key('listView'),
            child: Column(children: <Widget>[
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('firstName'),
                decoration: const InputDecoration(labelText: 'First Name'),
                controller: _firstNameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your first name?';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('lastName'),
                decoration: const InputDecoration(labelText: 'Last Name'),
                controller: _lastNameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your last name?';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('A temporary password will be send by email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                  )),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('email'),
                decoration: const InputDecoration(
                    labelText: 'Email address = Username'),
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
              TextFormField(
                key: const Key('companyName'),
                decoration: const InputDecoration(labelText: 'Business name'),
                controller: _companyController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter business name("Private" for Private person)';
                  }
                  return null;
                },
              ),
              Visibility(
                  visible: !widget.admin,
                  child: Column(children: [
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton(
                              key: const Key('newCustomer'),
                              child: const Text('Register as a customer'),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthRegisterUserEcommerce(
                                        User(
                                          company: Company(
                                              name: _companyController.text),
                                          firstName: _firstNameController.text,
                                          lastName: _lastNameController.text,
                                          email: _emailController.text,
                                        ),
                                      ));
                                }
                              })),
                    ])
                  ])),
              const SizedBox(height: 20),
              Visibility(
                  // register new company and admin
                  visible: widget.admin,
                  child: Column(children: [
                    DropdownButtonFormField<Currency>(
                      key: const Key('currency'),
                      decoration: const InputDecoration(labelText: 'Currency'),
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
                    Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                          border: Border.all(
                              color: Colors.black45,
                              style: BorderStyle.solid,
                              width: 0.80),
                        ),
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
                    Row(children: [
                      Expanded(
                          child: ElevatedButton(
                              key: const Key('newCompany'),
                              child: const Text(
                                  'Register AND create a new Company'),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthRegisterCompanyAndAdmin(
                                          User(
                                            company: Company(
                                                name: _companyController.text),
                                            firstName:
                                                _firstNameController.text,
                                            lastName: _lastNameController.text,
                                            email: _emailController.text,
                                          ),
                                          (_currencySelected.currencyId!),
                                          _demoData));
                                }
                              })),
                    ])
                  ]))
            ])));
  }
}
