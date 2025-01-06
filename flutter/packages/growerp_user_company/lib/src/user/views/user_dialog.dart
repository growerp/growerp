// ignore_for_file: unnecessary_string_interpolations

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

import 'package:universal_io/io.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_user_company.dart';

class UserDialog extends StatelessWidget {
  final User user;
  const UserDialog(this.user, {super.key});
  @override
  Widget build(BuildContext context) {
    if (user.company == null) return UserDialogStateFull(user);
    return BlocProvider<CompanyBloc>(
        create: (context) =>
            CompanyBloc(context.read<RestClient>(), user.company!.role),
        child: UserDialogStateFull(user));
  }
}

class UserDialogStateFull extends StatefulWidget {
  final User user;
  const UserDialogStateFull(this.user, {super.key});
  @override
  UserDialogState createState() => UserDialogState();
}

class UserDialogState extends State<UserDialogStateFull> {
  late final GlobalKey<FormState> _userDialogFormKey;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _loginNameController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _companySearchBoxController = TextEditingController();

  bool loading = false;
  late List<UserGroup> localUserGroups;
  late UserGroup _selectedUserGroup;
  late Role _selectedRole;
  Company _selectedCompany = Company();
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  late User updatedUser;
  final ImagePicker _picker = ImagePicker();
  late UserBloc _userBloc;
  late CompanyBloc _companyBloc;
  late AuthBloc _authBloc;
  bool _isLoginDisabled = false;
  late bool isPhone;
  bool _hasLogin = false;
  final ScrollController _scrollController = ScrollController();
  late User currentUser;
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    _userDialogFormKey = GlobalKey<FormState>();

    if (widget.user.partyId != null) {
      _idController.text = widget.user.pseudoId ?? '';
      _firstNameController.text = widget.user.firstName ?? '';
      _lastNameController.text = widget.user.lastName ?? '';
      _loginNameController.text = widget.user.loginName ?? '';
      _telephoneController.text = widget.user.telephoneNr ?? '';
      _emailController.text = widget.user.email ?? '';
      _isLoginDisabled = widget.user.loginDisabled ?? false;
      _hasLogin = widget.user.userId != null;
    }
    _selectedCompany = widget.user.company ?? Company(role: Role.unknown);
    _selectedRole =
        widget.user.role ?? widget.user.company!.role ?? Role.unknown;
    _selectedUserGroup = widget.user.userGroup ?? UserGroup.employee;
    localUserGroups = UserGroup.values;
    updatedUser = widget.user;
    _userBloc = context.read<UserBloc>();
    _authBloc = context.read<AuthBloc>();
    currentUser = _authBloc.state.authenticate!.user!;
    _companyBloc = context.read<CompanyBloc>()
      ..add(CompanyFetch(
          ownerPartyId: _authBloc.state.authenticate!.ownerPartyId!,
          limit: 3,
          isForDropDown: true));
    isAdmin = context.read<AuthBloc>().state.authenticate!.user!.userGroup ==
        UserGroup.admin;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onImageButtonPressed(ImageSource source,
      {BuildContext? context}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
      );
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _imageFile = response.file;
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    String title = '';
    if (_selectedRole == Role.company) {
      title = widget.user.userGroup != null &&
              widget.user.userGroup == UserGroup.admin
          ? 'Admininistrator'
          : 'Employee';
    } else {
      title = _selectedRole.name;
    }
    return Dialog(
      key: Key('UserDialog${_selectedRole.name}'),
      insetPadding: const EdgeInsets.all(10),
      child: popUp(
          context: context,
          title: "$title #${widget.user.pseudoId ?? ' new'}",
          width: isPhone ? 400 : 1000,
          height: isPhone ? 700 : 700,
          child: Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton:
                  ImageButtons(_scrollController, _onImageButtonPressed),
              body: BlocConsumer<UserBloc, UserState>(
                  listenWhen: (previous, current) =>
                      previous.status == UserStatus.loading,
                  listener: (context, state) {
                    if (state.status == UserStatus.failure) {
                      loading = false;
                      HelperFunctions.showMessage(
                          context, state.message, Colors.red);
                    }
                    if (state.status == UserStatus.success) {
                      Navigator.of(context).pop(state.users[0]);
                    }
                  },
                  builder: (context, state) {
                    if (state.status == UserStatus.loading) {
                      return const LoadingIndicator();
                    }
                    return listChild();
                  }))),
    );
  }

  Widget listChild() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? FutureBuilder<void>(
            future: retrieveLostData(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Pick image error: ${snapshot.error}}',
                  textAlign: TextAlign.center,
                );
              }
              return _showForm();
            })
        : _showForm();
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    }
    return _userDialog();
  }

  Widget _userDialog() {
    List<Widget> widgets = [
      InputDecorator(
        decoration: InputDecoration(
          labelText: 'User information',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('id'),
                    decoration: const InputDecoration(labelText: 'ID'),
                    controller: _idController,
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<Role>(
                    key: const Key('role'),
                    decoration: const InputDecoration(labelText: 'Role'),
                    hint: const Text('Role'),
                    value: _selectedRole,
                    validator: (value) =>
                        value == Role.unknown ? 'Select a valid role!' : null,
                    items: Role.values.map((item) {
                      return DropdownMenuItem<Role>(
                          value: item, child: Text(item.value));
                    }).toList(),
                    onChanged: (Role? newValue) {
                      setState(() {
                        _selectedRole = newValue!;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
              ],
            ),
            Row(children: [
              Expanded(
                  child: TextFormField(
                key: const Key('firstName'),
                decoration: const InputDecoration(labelText: 'First Name'),
                controller: _firstNameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a first name?';
                  return null;
                },
              )),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: const Key('lastName'),
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  controller: _lastNameController,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter a last name?';
                    return null;
                  },
                ),
              )
            ]),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('userEmail'),
                    decoration:
                        const InputDecoration(labelText: 'Email address'),
                    controller: _emailController,
                    validator: (String? value) {
                      if (value!.isNotEmpty &&
                          !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                              .hasMatch(value)) {
                        return 'This is not a valid email';
                      }
                      if (value.isEmpty &&
                          _loginNameController.text.isNotEmpty) {
                        return 'Email for login required!';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('userTelephoneNr'),
                    decoration:
                        const InputDecoration(labelText: 'Telephone number'),
                    controller: _telephoneController,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Postal Address',
          ),
          child: Row(children: [
            Expanded(
                child: InkWell(
                    key: const Key('address'),
                    onTap: () async {
                      var result = await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return AddressDialog(address: updatedUser.address);
                          });
                      if (!mounted) return;
                      if (result is Address) {
                        setState(() {
                          updatedUser = updatedUser.copyWith(address: result);
                        });
                      }
                    },
                    child: Row(children: [
                      Expanded(
                        child: Text(
                            updatedUser.address?.address1 != null &&
                                    updatedUser.address?.address2 != "_DELETE_"
                                ? "${updatedUser.address?.city} "
                                    "${updatedUser.address?.country ?? ''}"
                                : "No postal address yet",
                            key: const Key('addressLabel')),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_drop_down),
                          const SizedBox(width: 10),
                          if (updatedUser.address != null &&
                              updatedUser.address?.address2 != "_DELETE_")
                            IconButton(
                              key: const Key('deleteAddress'),
                              onPressed: isAdmin
                                  ? () => setState(() => updatedUser =
                                      updatedUser.copyWith(
                                          address: updatedUser.address!
                                              .copyWith(address2: "_DELETE_")))
                                  : null,
                              icon: const Icon(Icons.clear),
                            ),
                        ],
                      )
                    ]))),
          ])),
      InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Payment method',
          ),
          child: Row(children: [
            Expanded(
                child: InkWell(
                    key: const Key('paymentMethod'),
                    onTap: isAdmin && updatedUser.address != null
                        ? () async {
                            var result = await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return PaymentMethodDialog(
                                      paymentMethod: updatedUser.paymentMethod);
                                });
                            if (!mounted) return;
                            if (result is PaymentMethod) {
                              setState(() {
                                updatedUser =
                                    updatedUser.copyWith(paymentMethod: result);
                              });
                            }
                          }
                        : null,
                    child: Row(children: [
                      Expanded(
                        child: Text(
                            updatedUser.paymentMethod != null &&
                                    updatedUser.paymentMethod?.ccDescription !=
                                        "_DELETE_"
                                ? "${updatedUser.paymentMethod?.ccDescription}"
                                : "No payment methods yet"
                                    "${updatedUser.address == null ? ",\nneed postal address to add" : ""}",
                            key: const Key('paymentMethodLabel')),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_drop_down),
                          const SizedBox(width: 10),
                          if (updatedUser.paymentMethod != null &&
                              updatedUser.paymentMethod?.ccDescription !=
                                  "_DELETE_")
                            IconButton(
                                key: const Key('deletePaymentMethod'),
                                onPressed: isAdmin &&
                                        updatedUser.paymentMethod != null
                                    ? () => setState(() => updatedUser =
                                        updatedUser.copyWith(
                                            paymentMethod: updatedUser
                                                .paymentMethod!
                                                .copyWith(
                                                    ccDescription: "_DELETE_")))
                                    : null,
                                icon: const Icon(Icons.clear)),
                        ],
                      )
                    ]))),
          ])),
      if (_selectedRole != Role.company)
        InputDecorator(
            decoration: InputDecoration(
                labelText: "${_selectedCompany.role?.value ?? Role.unknown}"
                    " Company information"),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: BlocBuilder<CompanyBloc, CompanyState>(
                      builder: (context, state) {
                    switch (state.status) {
                      case CompanyStatus.failure:
                        return const FatalErrorForm(
                            message: 'server connection problem');
                      case CompanyStatus.success:
                        return DropdownSearch<Company>(
                          key: const Key('userCompanyName'),
                          selectedItem: _selectedCompany.name == null
                              ? Company(name: '')
                              : _selectedCompany,
                          popupProps: PopupProps.menu(
                            showSelectedItems: true,
                            isFilterOnline: true,
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              autofocus: true,
                              decoration: const InputDecoration(
                                  labelText: "company,name"),
                              controller: _companySearchBoxController,
                            ),
                            menuProps: MenuProps(
                                borderRadius: BorderRadius.circular(20.0)),
                            title: popUp(
                              context: context,
                              title: 'Select company',
                              height: 50,
                              width: 450,
                            ),
                          ),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Company name[id]')),
                          itemAsString: (Company? u) => u?.partyId == null
                              ? ''
                              : " ${u!.name}[${u.pseudoId ?? ''}]",
                          asyncItems: (String filter) {
                            _companyBloc.add(CompanyFetch(
                              ownerPartyId:
                                  _authBloc.state.authenticate!.ownerPartyId!,
                              searchString: filter,
                              limit: 3,
                              isForDropDown: true,
                            ));
                            return Future.delayed(
                                const Duration(milliseconds: 100), () {
                              return Future.value(_companyBloc.state.companies);
                            });
                          },
                          compareFn: (item, sItem) =>
                              item.partyId == sItem.partyId,
                          onChanged: (Company? newValue) {
                            setState(() {
                              _selectedCompany = newValue ?? Company();
                            });
                          },
                          validator: (value) =>
                              value == null && _companyController.text == ''
                                  ? "Select an existing or Create a new company"
                                  : null,
                        );
                      default:
                        return const Center(child: LoadingIndicator());
                    }
                  }),
                ),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_selectedCompany.name != null)
                    Expanded(
                        child: OutlinedButton(
                      key: const Key('editCompany'),
                      onPressed: () async {
                        var result = await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return ShowCompanyDialog(_selectedCompany,
                                  dialog: true);
                            });
                        if (result is Company) {
                          setState(() {
                            _selectedCompany = result;
                            _selectedRole = result.role!;
                          });
                        }
                      },
                      child: const Text('Update Company'),
                    )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OutlinedButton(
                    key: const Key('newCompany'),
                    onPressed: () async {
                      var result = await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return ShowCompanyDialog(
                                Company(partyId: '_NEW_', role: _selectedRole));
                          });
                      if (result is Company) {
                        setState(() {
                          _selectedCompany = result;
                          _selectedRole = result.role!;
                        });
                      }
                    },
                    child: const Text('New Company'),
                  )),
                ],
              ),
            ])),
      InputDecorator(
          decoration: InputDecoration(
            labelText: 'User Login',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
          child: Column(children: [
            TextFormField(
              readOnly: !(currentUser.userGroup == UserGroup.admin),
              key: const Key('loginName'),
              decoration: const InputDecoration(labelText: 'User Login Name '),
              controller: _loginNameController,
              onChanged: (value) {
                if (value.isNotEmpty != _hasLogin) {
                  return setState(() {
                    _hasLogin = !_hasLogin;
                  });
                }
              },
              validator: (value) {
                if (widget.user.userGroup == UserGroup.admin &&
                    value!.isEmpty) {
                  return 'An administrator needs a username!';
                }
                return null;
              },
            ),
            if (currentUser.userGroup == UserGroup.admin &&
                _loginNameController.text.isNotEmpty)
              Column(children: [
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: DropdownButtonFormField<UserGroup>(
                    decoration:
                        const InputDecoration(labelText: 'Security User Group'),
                    key: const Key('userGroup'),
                    hint: const Text('Security User Group'),
                    value: _selectedUserGroup,
                    validator: (value) =>
                        value == null ? 'field required' : null,
                    items: localUserGroups.map((item) {
                      return DropdownMenuItem<UserGroup>(
                          value: item, child: Text(item.name));
                    }).toList(),
                    onChanged: (UserGroup? newValue) {
                      setState(() {
                        _selectedUserGroup = newValue!;
                      });
                    },
                    isExpanded: true,
                  )),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    height: 60,
                    child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Disabled',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        child: Checkbox(
                          key: const Key('loginDisabled'),
                          value: _isLoginDisabled,
                          onChanged: (bool? value) {
                            setState(() {
                              _isLoginDisabled = value!;
                            });
                          },
                        )),
                  )
                ])
              ])
          ]))
    ];
    Widget updateButton = Row(children: [
      if (widget.user.partyId != null)
        OutlinedButton(
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red)),
            key: const Key('deleteUser'),
            child: const Text('Delete User'),
            onPressed: () async {
              var result =
                  await confirmDeleteUserComp(context, widget.user.userGroup!);
              if (result != null) {
                if (!mounted) return;
                // delete company too?
                if (widget.user.partyId == currentUser.partyId!) {
                  _userBloc.add(UserDelete(widget.user.copyWith(image: null)));
                  Navigator.of(context).pop(updatedUser);
                  context.read<AuthBloc>().add(const AuthLoggedOut());
                } else {
                  _userBloc.add(UserDelete(widget.user.copyWith(image: null)));
                }
              }
            }),
      const SizedBox(width: 10),
      Expanded(
          child: OutlinedButton(
              key: const Key('updateUser'),
              child: Text(updatedUser.partyId == null ? 'Create' : 'Update'),
              onPressed: () async {
                if (_userDialogFormKey.currentState!.validate()) {
                  updatedUser = updatedUser.copyWith(
                      pseudoId: _idController.text,
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      email: _emailController.text,
                      loginName: _loginNameController.text,
                      telephoneNr: _telephoneController.text,
                      address: updatedUser.address,
                      paymentMethod: updatedUser.paymentMethod,
                      loginDisabled: _isLoginDisabled,
                      userGroup: _selectedUserGroup,
                      role: _selectedRole,
//                      language: Localizations.localeOf(context)
//                          .languageCode
//                          .toString(),
                      company: _selectedCompany.copyWith(role: _selectedRole),
                      image: await HelperFunctions.getResizedImage(
                          _imageFile?.path));
                  if (!mounted) return;
                  if (_imageFile?.path != null && updatedUser.image == null) {
                    HelperFunctions.showMessage(
                        context, "Image upload error!", Colors.red);
                  } else {
                    _userBloc.add(UserUpdate(updatedUser));
                    // if logged-in user update authBloc
                    if (_authBloc.state.authenticate!.user!.partyId ==
                        updatedUser.partyId) {
                      _authBloc.add(AuthLoad());
                    }
                  }
                }
              }))
    ]);

    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(padding: const EdgeInsets.all(10), child: widgets[i]));
    }
    column.add(updateButton);

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      rows.add(const SizedBox(height: 20));
      rows.add(SizedBox(
          height: 400,
          child: MasonryGridView.count(
            itemCount: widgets.length,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemBuilder: (context, index) {
              return widgets[index];
            },
          )));
      rows.add(updateButton);
    }

    return Form(
        key: _userDialogFormKey,
        child: SingleChildScrollView(
            controller: _scrollController,
            key: const Key('listView'),
            child: Column(children: <Widget>[
              const SizedBox(height: 10),
              CircleAvatar(
                  radius: 60,
                  child: _imageFile != null
                      ? kIsWeb
                          ? Image.network(_imageFile!.path, scale: 0.3)
                          : Image.file(File(_imageFile!.path), scale: 0.3)
                      : widget.user.image != null
                          ? Image.memory(widget.user.image!, scale: 0.3)
                          : Text(widget.user.firstName?.substring(0, 1) ?? '',
                              style: const TextStyle(fontSize: 30))),
              Column(children: rows.isNotEmpty ? rows : column),
            ])));
  }
}
