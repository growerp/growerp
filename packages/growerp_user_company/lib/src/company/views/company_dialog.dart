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

import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../growerp_user_company.dart';

/// a class to start the <CompanyDialog> from anywhere
/// 1. a null [Company] input will show the current main company information
/// from the [AuthBloc]
/// 2. a [Company.partyId] = "_NEW_" will show an empty form in order
///  to create a new company
/// 3. a [Company.partyId] will retrieve the company from repos
class ShowCompanyDialog extends StatelessWidget {
  final Company company;
  final bool dialog;
  const ShowCompanyDialog(this.company, {super.key, this.dialog = true});
  @override
  Widget build(BuildContext context) {
    CompanyUserAPIRepository repos = CompanyUserAPIRepository(
        context.read<AuthBloc>().state.authenticate!.apiKey!);
    return BlocProvider<CompanyBloc>(
        create: (context) =>
            CompanyBloc(repos, company.role, context.read<AuthBloc>())
              ..add(CompanyFetch(companyPartyId: company.partyId ?? '')),
        child: company.partyId != '_NEW_'
            ? BlocBuilder<CompanyBloc, CompanyState>(
                builder: (context, state) {
                  if (state.status == CompanyStatus.success) {
                    return RepositoryProvider.value(
                        value: repos,
                        child: CompanyDialog(
                            state.companies.isNotEmpty
                                ? state.companies[0]
                                : company,
                            dialog: dialog));
                  } else {
                    return const LoadingIndicator();
                  }
                },
              )
            : CompanyDialog(company, dialog: dialog));
  }
}

class CompanyDialog extends StatefulWidget {
  final Company company;
  final bool dialog;
  const CompanyDialog(this.company, {super.key, this.dialog = true});
  @override
  CompanyFormState createState() => CompanyFormState();
}

class CompanyFormState extends State<CompanyDialog> {
  late Authenticate authenticate;
  late User user;
  late List<User> employees;
  late Company company;
  late Role _selectedRole;
  final _nameController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vatPercController = TextEditingController();
  final _salesPercController = TextEditingController();
  late Currency _selectedCurrency;
  late bool isAdmin;
  late final GlobalKey<ScaffoldMessengerState> _companyDialogKey;
  late final GlobalKey<FormState> _companyDialogFormKey;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  final ImagePicker _picker = ImagePicker();
  late bool isPhone;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _companyDialogKey = GlobalKey<ScaffoldMessengerState>();
    _companyDialogFormKey = GlobalKey<FormState>();
    authenticate = context.read<AuthBloc>().state.authenticate!;
    if (widget.company.partyId == null) {
      company = authenticate.company!;
    } else if (widget.company.partyId == '_NEW_') {
      company = Company(role: widget.company.role);
    } else {
      company = widget.company;
    }
    user = authenticate.user!;
    employees = List.of(company.employees);
    isAdmin = authenticate.user!.userGroup == UserGroup.admin;
    if (company.currency != null) {
      _selectedCurrency = currencies.firstWhere(
          (element) => element.currencyId == company.currency?.currencyId);
    } else {
      _selectedCurrency = Currency(currencyId: '', description: '');
    }
    _nameController.text = company.name ?? '';
    _selectedRole = company.role ?? Role.unknown;
    _emailController.text = company.email ?? '';
    _vatPercController.text =
        company.vatPerc == null ? '' : company.vatPerc.toString();
    _salesPercController.text =
        company.salesPerc == null ? '' : company.salesPerc.toString();
    if (company.telephoneNr != null) {
      _telephoneController.text = company.telephoneNr!;
    }
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
    return BlocConsumer<CompanyBloc, CompanyState>(
        listenWhen: (previous, current) =>
            previous.status == CompanyStatus.loading,
        listener: (context, state) {
          if (state.status == CompanyStatus.failure) {
            // message on this dialog
            _companyDialogKey.currentState!.showSnackBar(
                snackBar(context, Colors.red, state.message ?? ''));
          }
          if (state.status == CompanyStatus.success) {
            // message on parent page
            HelperFunctions.showMessage(context, state.message, Colors.green);
            if (widget.dialog == true) {
              Navigator.of(context).pop(state.companies[0]);
            }
          }
        },
        builder: (context, state) {
          if (state.status == CompanyStatus.loading) const LoadingIndicator();
          return widget.dialog == true
              ? Dialog(
                  key:
                      Key('CompanyDialog${company.role?.name ?? Role.unknown}'),
                  insetPadding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: popUp(
                      context: context,
                      title: "$_selectedRole Company information",
                      width: isPhone ? 400 : 1000,
                      height: isPhone ? 600 : 750,
                      child: listChild()))
              : listChild();
        });
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
    // process related employees
    List<Widget> employeeChips = [];
    employees.asMap().forEach((index, employee) {
      employeeChips.add(InputChip(
        label: Text(
          "${employee.firstName} ${employee.lastName}",
          key: Key(index.toString()),
        ),
        deleteIcon: const Icon(
          Icons.cancel,
          key: Key("deleteEmployee"),
        ),
        onPressed: () async {
          var result = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return ShowUserDialog(employee.copyWith(company: company));
              });
          if (result != null) {
            setState(() {
              employees[index] = result;
            });
          }
        },
/*        onDeleted: () async {
          bool? result = await confirmDialog(context,
              "Remove ${employee.firstName} ${employee.lastName}?", "");
          if (result == true) {
            setState(() {
              _selectedCategories.removeAt(index);
              if (_selectedCategories.isEmpty) {
                _selectedCategories.add(Category(categoryId: 'allDelete'));
              }
              _websiteBloc.add(WebsiteUpdate(Website(
                  id: state.website!.id,
                  productCategories: _selectedCategories)));

            });
          }
        },
*/
      ));
    });
    employeeChips.add(IconButton(
        key: const Key('addEmployee'),
        iconSize: 30,
        icon: const Icon(Icons.add_circle),
        color: Colors.deepOrange,
        padding: const EdgeInsets.all(0.0),
        onPressed: () async {
          User? result = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return ShowUserDialog(User(company: company));
              });
          if (result != null) {
            setState(() {
              employees.add(result);
            });
          }
        }));

    List<Widget> widgets = [
      TextFormField(
        readOnly: !isAdmin,
        key: const Key('companyName'),
        decoration: const InputDecoration(labelText: 'Company Name'),
        controller: _nameController,
        validator: (value) {
          if (value!.isEmpty) return 'Please enter the company Name?';
          return null;
        },
      ),
      Row(
        children: [
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
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<Currency>(
              key: const Key('currency'),
              decoration: const InputDecoration(labelText: 'Currency'),
              hint: const Text('Currency'),
              value: _selectedCurrency,
              items: currencies.map((item) {
                return DropdownMenuItem<Currency>(
                    value: item, child: Text(item.description!));
              }).toList(),
              onChanged: isAdmin
                  ? (Currency? newValue) {
                      setState(() {
                        _selectedCurrency = newValue!;
                      });
                    }
                  : null,
              isExpanded: true,
            ),
          ),
        ],
      ),
      TextFormField(
        key: const Key('telephoneNr'),
        decoration: const InputDecoration(labelText: 'Telephone number'),
        controller: _telephoneController,
      ),
      TextFormField(
        readOnly: !isAdmin,
        key: const Key('email'),
        decoration: const InputDecoration(labelText: 'Company Email address'),
        controller: _emailController,
        validator: (value) {
          if (value != null &&
              value.isNotEmpty &&
              !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                  .hasMatch(value)) {
            return 'This is not a valid email';
          }
          return null;
        },
      ),
      Row(children: [
        Expanded(
            child: TextFormField(
          key: const Key('vatPerc'),
          readOnly: !isAdmin,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(labelText: 'VAT. percentage'),
          controller: _vatPercController,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: TextFormField(
          key: const Key('salesPerc'),
          readOnly: !isAdmin,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(labelText: 'Sales Tax percentage'),
          controller: _salesPercController,
        ))
      ]),
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
                            return AddressDialog(address: company.address);
                          });
                      if (!mounted) return;
                      if (result is Address) {
                        setState(() {
                          company = company.copyWith(address: result);
                        });
                      }
                    },
                    child: Row(children: [
                      Expanded(
                        child: Text(
                            company.address?.address1 != null &&
                                    company.address?.address2 != "_DELETE_"
                                ? "${company.address?.city} "
                                    "${company.address?.country!}"
                                : "No postal address yet",
                            key: const Key('addressLabel')),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_drop_down),
                          const SizedBox(width: 10),
                          if (company.address != null &&
                              company.address?.address2 != "_DELETE_")
                            IconButton(
                              key: const Key('deleteAddress'),
                              onPressed: isAdmin
                                  ? () => setState(() => company =
                                      company.copyWith(
                                          address: company.address!
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
                    onTap: isAdmin && company.address != null
                        ? () async {
                            var result = await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return PaymentMethodDialog(
                                      paymentMethod: company.paymentMethod);
                                });
                            if (!mounted) return;
                            if (result is PaymentMethod) {
                              setState(() {
                                company =
                                    company.copyWith(paymentMethod: result);
                              });
                            }
                          }
                        : null,
                    child: Row(children: [
                      Expanded(
                        child: Text(
                            company.paymentMethod != null &&
                                    company.paymentMethod?.ccDescription !=
                                        "_DELETE_"
                                ? "${company.paymentMethod?.ccDescription}"
                                : "No payment methods yet"
                                    "${company.address == null ? ",\nneed address to add" : ""}",
                            key: const Key('paymentMethodLabel')),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_drop_down),
                          const SizedBox(width: 10),
                          if (company.paymentMethod != null &&
                              company.paymentMethod?.ccDescription !=
                                  "_DELETE_")
                            IconButton(
                                key: const Key('deletePaymentMethod'),
                                onPressed: isAdmin &&
                                        company.paymentMethod != null
                                    ? () => setState(() => company =
                                        company.copyWith(
                                            paymentMethod:
                                                company.paymentMethod!.copyWith(
                                                    ccDescription: "_DELETE_")))
                                    : null,
                                icon: const Icon(Icons.clear)),
                        ],
                      )
                    ]))),
          ]))
    ];

    Widget updateButton = Row(children: [
      Expanded(
          child: Visibility(
              visible: isAdmin,
              child: ElevatedButton(
                  key: const Key('update'),
                  onPressed: isAdmin
                      ? () async {
                          if (_companyDialogFormKey.currentState!.validate()) {
                            company = Company(
                                partyId: company.partyId,
                                email: _emailController.text,
                                name: _nameController.text,
                                role: _selectedRole,
                                telephoneNr: _telephoneController.text,
                                currency: _selectedCurrency,
                                address: company.address,
                                paymentMethod: company.paymentMethod,
                                vatPerc: Decimal.parse(
                                    _vatPercController.text.isEmpty
                                        ? '0'
                                        : _vatPercController.text),
                                salesPerc: Decimal.parse(
                                    _salesPercController.text.isEmpty
                                        ? '0'
                                        : _salesPercController.text),
                                image: await HelperFunctions.getResizedImage(
                                    _imageFile?.path));
                            if (!mounted) return;
                            if (_imageFile?.path != null &&
                                company.image == null) {
                              HelperFunctions.showMessage(
                                  context, "Image upload error!", Colors.red);
                            } else {
                              context
                                  .read<CompanyBloc>()
                                  .add(CompanyUpdate(company));
                            }
                          }
                        }
                      : null,
                  child: Text(
                    company.partyId == null ? 'Create' : 'Update',
                  ))))
    ]);

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(5), child: widgets[i++])),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: i < widgets.length ? widgets[i] : Container()))
          ],
        ));
      }
    }
    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(padding: const EdgeInsets.all(5), child: widgets[i]));
    }

    return ScaffoldMessenger(
        key: _companyDialogKey,
        child: Scaffold(
            key: Key('CompanyDialog${company.role?.value ?? Role.unknown}'),
            backgroundColor: Colors.transparent,
            floatingActionButton:
                ImageButtons(_scrollController, _onImageButtonPressed),
            body: Form(
                key: _companyDialogFormKey,
                child: SingleChildScrollView(
                    controller: _scrollController,
                    key: const Key('listView'),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                        child: Column(children: [
                          Center(
                              child: Text(
                            'id:#${company.partyId ?? 'New'}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            key: const Key('header'),
                          )),
                          const SizedBox(height: 10),
                          CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 60,
                              child: _imageFile != null
                                  ? kIsWeb
                                      ? Image.network(_imageFile!.path,
                                          scale: 0.3)
                                      : Image.file(File(_imageFile!.path),
                                          scale: 0.3)
                                  : company.image != null
                                      ? Image.memory(company.image!, scale: 0.3)
                                      : Text(
                                          company.name != null
                                              ? company.name!.substring(0, 1)
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 30,
                                              color: Colors.black))),
                          const SizedBox(height: 10),
                          Column(children: (rows.isEmpty ? column : rows)),
                          updateButton,
                          const SizedBox(height: 10),
                          InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Employees',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                              ),
                              child:
                                  Wrap(spacing: 10, children: employeeChips)),
                        ]))))));
  }
}
