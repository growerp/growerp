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

class NewCompanyDialog extends StatelessWidget {
  final FormArguments formArguments;
  const NewCompanyDialog({Key? key, required this.formArguments})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NewCompanyHeader(
        message: formArguments.message,
        authenticate: formArguments.object as Authenticate);
  }
}

class NewCompanyHeader extends StatefulWidget {
  final String? message;
  final Authenticate authenticate;
  const NewCompanyHeader({this.message, required this.authenticate});

  @override
  State<NewCompanyHeader> createState() => _NewCompanyHeaderState(message);
}

class _NewCompanyHeaderState extends State<NewCompanyHeader> {
  final String? message;
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  late bool _demoData;
  late Currency _currencySelected;
  _NewCompanyHeaderState(this.message);

  @override
  void initState() {
    Future<Null>.delayed(Duration(milliseconds: 0), () {
      if (message != null)
        HelperFunctions.showMessage(context, '$message', Colors.green);
    });
    super.initState();
    _companyController..text = kReleaseMode ? '' : 'Demo company from John Doe';
    _firstNameController..text = kReleaseMode ? '' : 'John';
    _lastNameController..text = kReleaseMode ? '' : 'Doe';
    _emailController..text = kReleaseMode ? '' : 'test@example.com';
    _demoData = kReleaseMode ? false : true;
    _currencySelected = currencies[0];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(listener: (context, state) {
      if (state.status == AuthStatus.failure)
        HelperFunctions.showMessage(context, state.message, Colors.red);
      if (state.status == AuthStatus.registered) {
        Navigator.pop(context);
      }
    }, child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.loading) return LoadingIndicator();
      return Scaffold(
          backgroundColor: Colors.transparent,
          body: Dialog(
              insetPadding: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                    padding: EdgeInsets.all(20),
                    width: 400,
                    height: 650,
                    child: _registerForm(widget.authenticate, state)),
                Positioned(top: 5, right: 5, child: DialogCloseButton())
              ])));
    }));
  }

  Widget _registerForm(Authenticate authenticate, AuthState state) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            key: Key('listView'),
            child: Column(children: <Widget>[
              SizedBox(height: 20),
              Center(
                  child: Text(
                      authenticate.company != null
                          ? "Enter a new customer for company\n "
                              "${authenticate.company!.name}"
                          : "Enter a new company with admin user",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold))),
              SizedBox(height: 20),
              TextFormField(
                key: Key('firstName'),
                decoration: InputDecoration(labelText: 'First Name'),
                controller: _firstNameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your first name?';
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                key: Key('lastName'),
                decoration: InputDecoration(labelText: 'Last Name'),
                controller: _lastNameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your last name?';
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text('A temporary password will be send by email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                  )),
              SizedBox(height: 10),
              TextFormField(
                key: Key('email'),
                decoration:
                    InputDecoration(labelText: 'Email address = Username'),
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
              SizedBox(height: 20),
              TextFormField(
                key: Key('companyName'),
                decoration: InputDecoration(labelText: 'Business name'),
                controller: _companyController,
                validator: (value) {
                  if (value!.isEmpty)
                    return 'Please enter business name("Private" for Private person)';
                  return null;
                },
              ),
              Visibility(
                  visible: authenticate.company?.partyId != null,
                  child: Column(children: [
                    SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton(
                              key: Key('newCustomer'),
                              child: Text('Register as a customer'),
                              onPressed: () {
                                if (_formKey.currentState!.validate())
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthRegisterUserEcommerce(
                                        User(
                                          companyName: _companyController.text,
                                          firstName: _firstNameController.text,
                                          lastName: _lastNameController.text,
                                          email: _emailController.text,
                                        ),
                                      ));
                              })),
                    ])
                  ])),
              SizedBox(height: 20),
              Visibility(
                  // register new company and admin
                  visible: authenticate.company == null,
                  child: Column(children: [
                    DropdownButtonFormField<Currency>(
                      key: Key('currency'),
                      decoration: InputDecoration(labelText: 'Currency'),
                      hint: Text('Currency'),
                      value: _currencySelected,
                      validator: (value) =>
                          value == null ? 'Currency field required!' : null,
                      items: currencies.map((item) {
                        return DropdownMenuItem<Currency>(
                            child: Text(item.description!), value: item);
                      }).toList(),
                      onChanged: (Currency? newValue) {
                        setState(() {
                          _currencySelected = newValue!;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 10),
                    Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                          border: Border.all(
                              color: Colors.black45,
                              style: BorderStyle.solid,
                              width: 0.80),
                        ),
                        child: CheckboxListTile(
                            key: Key('demoData'),
                            title: Text("Generate demo data"),
                            value: _demoData,
                            onChanged: (bool? value) {
                              setState(() {
                                _demoData = value!;
                              });
                            })),
                    SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton(
                              key: Key('newCompany'),
                              child: Text('Register AND create a new Company'),
                              onPressed: () {
                                if (_formKey.currentState!.validate())
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthRegisterCompanyAndAdmin(
                                          User(
                                            companyName:
                                                _companyController.text,
                                            firstName:
                                                _firstNameController.text,
                                            lastName: _lastNameController.text,
                                            email: _emailController.text,
                                          ),
                                          (_currencySelected.currencyId!),
                                          _demoData));
                              })),
                    ])
                  ]))
            ])));
  }
}
