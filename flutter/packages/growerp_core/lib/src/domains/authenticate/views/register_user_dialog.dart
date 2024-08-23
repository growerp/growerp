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

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import '../../domains.dart';

class RegisterUserDialog extends StatefulWidget {
  const RegisterUserDialog(this.admin, {super.key});

  final bool admin;

  @override
  State<RegisterUserDialog> createState() => _RegisterUserDialogState();
}

class _RegisterUserDialogState extends State<RegisterUserDialog> {
  final _registerFormKey = GlobalKey<FormState>();
  final _companySearchBoxController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  late AuthBloc _authBloc;
  late DataFetchBloc<Companies> _companyBloc;
  Company? _presetCompany;
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = kReleaseMode ? '' : 'John';
    _lastNameController.text = kReleaseMode ? '' : 'Doe';
    _emailController.text = kReleaseMode ? '' : 'test@example.com';
    _authBloc = context.read<AuthBloc>();
    _companyBloc = context.read<DataFetchBloc<Companies>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getCompanies(
            limit: 1,
          )));
    _presetCompany = context.read<Company?>();
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
                  title: "Registration",
                  height: 600,
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
              if (_presetCompany == null)
                const Text(
                    'Select an existing company, or leave empty for a new company',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                    )),
              if (_presetCompany == null) const SizedBox(height: 10),
              DropdownSearch<Company>(
                selectedItem: _selectedCompany,
                popupProps: PopupProps.menu(
                  showSelectedItems: true,
                  isFilterOnline: true,
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: " Company Name"),
                    controller: _companySearchBoxController,
                  ),
                  title: popUp(
                    context: context,
                    title: "Select Company",
                    height: 50,
                  ),
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Company',
                  ),
                ),
                key: const Key('selectCompany'),
                itemAsString: (Company? u) => "${u!.name}",
                asyncItems: (String filter) {
                  _companyBloc.add(GetDataEvent(
                      () => context.read<RestClient>().getCompanies(
                            searchString: filter,
                            limit: 3,
                          )));
                  return Future.delayed(const Duration(milliseconds: 1150), () {
                    return Future<List<Company>>.value(
                        (_companyBloc.state.data as Companies).companies);
                  });
                },
                compareFn: (item, sItem) => item.partyId == sItem.partyId,
                onChanged: (Company? newValue) {
                  setState(() {
                    _selectedCompany = newValue;
                  });
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                  key: const Key('newUserButton'),
                  child: const Text('Register'),
                  onPressed: () async {
                    if (_registerFormKey.currentState!.validate()) {
                      _authBloc.add(AuthRegister(User(
                        company: Company(partyId: _selectedCompany?.partyId),
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        email: _emailController.text,
                      )));
                    }
                  }),
            ])));
  }
}
