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
import 'package:models/@models.dart';
import '../helper_functions.dart';

class RegisterDialog extends StatelessWidget {
  final FormArguments formArguments;
  const RegisterDialog({Key? key, required this.formArguments})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? message = formArguments.message;
    return RegisterHeader(message);
  }
}

class RegisterHeader extends StatefulWidget {
  final String? message;
  const RegisterHeader(this.message);

  @override
  State<RegisterHeader> createState() => _RegisterHeaderState(message);
}

class _RegisterHeaderState extends State<RegisterHeader> {
  final String? message;
  final _formKey = GlobalKey<FormState>();
  Currency? _currencySelected = kReleaseMode ? null : currencies[0];
  final _companyController = TextEditingController()
    ..text = kReleaseMode ? '' : 'Demo company from John Doe';
  final _firstNameController = TextEditingController()
    ..text = kReleaseMode ? '' : 'John';
  final _lastNameController = TextEditingController()
    ..text = kReleaseMode ? '' : 'Doe';
  final _emailController = TextEditingController()
    ..text = kReleaseMode ? '' : 'admin@growerp.com';

  _RegisterHeaderState(this.message);

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
    Authenticate? authenticate;
    return BlocListener<AuthBloc, AuthState>(listener: (context, state) {
      if (state is AuthProblem)
        HelperFunctions.showMessage(context, state.errorMessage, Colors.red);
      if (state is AuthLoading)
        HelperFunctions.showMessage(
            context, 'Sending the registration...', Colors.green);
      if (state is AuthRegistered) {
        Navigator.pop(context);
      }
    }, child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthUnauthenticated) authenticate = state.authenticate;
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
                          child: Container(
                              padding: EdgeInsets.all(20),
                              width: 400,
                              height: 600,
                              child: _registerForm(authenticate, state)))))));
    }));
  }

  Widget _registerForm(Authenticate? authenticate, AuthState state) {
    return Form(
        key: _formKey,
        child: ListView(children: <Widget>[
          SizedBox(height: 20),
          Center(
              child: Text(
                  authenticate?.company != null
                      ? "Enter a new customer for company\n "
                          "${authenticate?.company!.name}"
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
            decoration: InputDecoration(labelText: 'Email address = Username'),
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
              visible: authenticate?.company?.partyId != null,
              child: Column(children: [
                SizedBox(height: 20),
                ElevatedButton(
                    key: Key('newCustomer'),
                    child: Text('Register as a customer'),
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          state is! UserLoading)
                        BlocProvider.of<AuthBloc>(context)
                            .add(RegisterUserEcommerce(
                          User(
                            companyName: _companyController.text,
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                          ),
                        ));
                    })
              ])),
          SizedBox(height: 20),
          Visibility(
              // register new company and admin
              visible: authenticate?.company?.partyId == null,
              child: Column(children: [
                SizedBox(height: 20),
                DropdownButtonFormField<Currency>(
                  key: Key('dropDownCur'),
                  hint: Text('Currency'),
                  value: _currencySelected,
                  validator: (value) =>
                      value == null ? 'Currency field required!' : null,
                  items: currencies.map((item) {
                    return DropdownMenuItem<Currency>(
                        child: Text(item.description ?? 'Currency??'),
                        value: item);
                  }).toList(),
                  onChanged: (Currency? newValue) {
                    setState(() {
                      _currencySelected = newValue;
                    });
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                    key: Key('newCompany'),
                    child: Text('Register AND create a new Company'),
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          state is! AuthLoading)
                        BlocProvider.of<AuthBloc>(context)
                            .add(RegisterCompanyAdmin(
                          User(
                            companyName: _companyController.text,
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                          ),
                          (_currencySelected?.currencyId ??
                              currencies[0].currencyId)!,
                        ));
                    }),
              ]))
        ]));
  }
}
