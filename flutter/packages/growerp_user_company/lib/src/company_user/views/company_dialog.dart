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

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_io/io.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';

import '../../common/common.dart';
import '../company_user.dart';
import 'user_dialog.dart';

/// a class to start the `CompanyDialog` from anywhere
/// 1. a null [Company] input will show the current main company information
/// from the [AuthBloc]
/// 2. a [Company.partyId] = "_NEW_" will show an empty form in order
///  to create a new company
/// 3. a [Company.partyId] will retrieve the company from restClient
/// 4. [dialog] will show either as a dialog or full screen
class ShowCompanyDialog extends StatelessWidget {
  final Company company;
  final bool dialog; // displayed as dialog or full screen
  const ShowCompanyDialog(this.company, {super.key, this.dialog = true});

  @override
  Widget build(BuildContext context) {
    var localizations = UserCompanyLocalizations.of(context)!;
    if (company.partyId != null && company.partyId != '_NEW_') {
      DataFetchBloc companyUserBloc = context.read<DataFetchBloc<Companies>>()
        ..add(
          GetDataEvent(
            () => context.read<RestClient>().getCompany(
              companyPartyId: company.partyId,
              limit: 1,
            ),
          ),
        );
      return BlocBuilder<DataFetchBloc<Companies>, DataFetchState<Companies>>(
        builder: (context, state) {
          if (state.status == DataFetchStatus.success ||
              state.status == DataFetchStatus.failure) {
            if ((companyUserBloc.state.data as Companies).companies.isEmpty) {
              return FatalErrorForm(
                message: localizations.companyNotFound(company.partyId!),
              );
            }
            return CompanyDialog(
              (companyUserBloc.state.data as Companies).companies[0],
            );
          }
          return const LoadingIndicator();
        },
      );
    }
    return CompanyDialog(company, dialog: dialog);
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
  List<User> employees = [];
  late Company company;
  Role _selectedRole = Role.unknown;
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _urlController = TextEditingController();
  final _vatPercController = TextEditingController();
  final _salesPercController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _backendController = TextEditingController();
  Currency? _selectedCurrency;
  late bool isAdmin;
  late final GlobalKey<FormState> _companyDialogFormKey;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  final ImagePicker _picker = ImagePicker();
  late bool isPhone;
  final ScrollController _scrollController = ScrollController();
  late CompanyUserBloc companyUserBloc;

  @override
  void initState() {
    super.initState();
    company = widget.company;
    companyUserBloc = context.read<CompanyUserBloc>();
    _companyDialogFormKey = GlobalKey<FormState>();
    AuthBloc authBloc = context.read<AuthBloc>();
    authenticate = authBloc.state.authenticate!;
    switch (widget.company.partyId) {
      case null:
        // main company
        authBloc.add(AuthLoad());
        company = authenticate.company!;
      case '_NEW_':
        company = widget.company.copyWith(partyId: null);
      default:
        company = widget.company;
    }

    employees = List.of(company.employees);
    if (company.currency != null && currencies.isNotEmpty) {
      _selectedCurrency = currencies.firstWhere(
        (element) => element.currencyId == company.currency?.currencyId,
        orElse: () => company.currency!,
      );
    }
    _idController.text = company.pseudoId ?? '';
    _nameController.text = company.name ?? '';
    _selectedRole = company.role ?? Role.unknown;
    _emailController.text = company.email ?? '';
    _urlController.text = company.url ?? '';
    _backendController.text = company.secondaryBackend ?? '';
    _hostNameController.text = company.hostName ?? '';
    _vatPercController.text = company.vatPerc == null
        ? ''
        : company.vatPerc.toString();
    _salesPercController.text = company.salesPerc == null
        ? ''
        : company.salesPerc.toString();
    if (company.telephoneNr != null) {
      _telephoneController.text = company.telephoneNr!;
    }

    user = authenticate.user!;
    isAdmin = authenticate.user!.userGroup == UserGroup.admin;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    var localizations = UserCompanyLocalizations.of(context)!;
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: Key('CompanyDialog${company.role?.name ?? Role.unknown}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: widget.dialog == true
          ? popUp(
              context: context,
              title: localizations.companyRoleDetail(
                _selectedRole.value,
                company.partyId == null
                    ? localizations.newItem
                    : company.pseudoId!,
              ),
              width: isPhone ? 400 : 1000,
              height: isPhone ? 700 : 750,
              child: listChild(localizations),
            )
          : listChild(localizations),
    );
  }

  Widget listChild(UserCompanyLocalizations localizations) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<CompanyUserBloc, CompanyUserState>(
          listener: (context, state) {
            if (state.status == CompanyUserStatus.failure) {
              HelperFunctions.showMessage(context, state.message, Colors.red);
            }
            if (state.status == CompanyUserStatus.success) {
              if (widget.dialog == true && _nameController.text != '') {
                Navigator.of(
                  context,
                ).pop(companyUserBloc.state.companiesUsers[0].getCompany());
              }
              final translatedMessage = state.message != null
                  ? translateUserCompanyBlocMessage(
                      localizations,
                      state.message!,
                    )
                  : '';
              if (translatedMessage.isNotEmpty) {
                HelperFunctions.showMessage(
                  context,
                  translatedMessage,
                  Colors.green,
                );
              }
            }
          },
          builder: (context, state) {
            if (state.status == CompanyUserStatus.loading) {
              return const LoadingIndicator();
            }
            return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? FutureBuilder<void>(
                    future: retrieveLostData(),
                    builder:
                        (BuildContext context, AsyncSnapshot<void> snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              localizations.pickImageError(
                                snapshot.error.toString(),
                              ),
                              textAlign: TextAlign.center,
                            );
                          }
                          return _showForm(localizations);
                        },
                  )
                : _showForm(localizations);
          },
        ),
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(UserCompanyLocalizations localizations) {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_pickImageError != null) {
      return Text(
        localizations.pickImageError(_pickImageError.toString()),
        textAlign: TextAlign.center,
      );
    }
    // process related employees
    List<Widget> employeeChips = [];
    employees.asMap().forEach((index, employee) {
      employeeChips.add(
        InputChip(
          label: Text(
            "${employee.firstName} ${employee.lastName}[${employee.pseudoId}]",
            key: Key("employee$index"),
          ),
          deleteIcon: const Icon(Icons.cancel, key: Key("deleteEmployee")),
          onPressed: () async {
            await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return ShowUserDialog(employee.copyWith(company: Company()));
              },
            );
            //          if (result != null) {
            //            setState(() {
            //              employees[index] = result;
            //            });
            //          }
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
        ),
      );
    });
    /*    employeeChips.add(IconButton(
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
                return UserDialog(User(company: company));
              });
          if (result != null) {
            setState(() {
              employees.add(result);
            });
          }
        }));
*/
    List<Widget> widgets = [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: const Key('id'),
              decoration: InputDecoration(labelText: localizations.id),
              controller: _idController,
            ),
          ),
          if (authenticate.company!.partyId != company.partyId)
            const SizedBox(width: 10),
          if (authenticate.company!.partyId != company.partyId)
            Expanded(
              child: DropdownButtonFormField<Role>(
                key: const Key('role'),
                decoration: InputDecoration(labelText: localizations.role),
                hint: Text(localizations.role),
                initialValue: _selectedRole,
                validator: (value) =>
                    value == Role.unknown ? localizations.roleError : null,
                items: Role.values.map((item) {
                  return DropdownMenuItem<Role>(
                    value: item,
                    child: Text(item.value),
                  );
                }).toList(),
                onChanged: _selectedRole != Role.unknown
                    ? null
                    : (Role? newValue) {
                        setState(() {
                          _selectedRole = newValue!;
                        });
                      },
                isExpanded: true,
              ),
            ),
        ],
      ),
      TextFormField(
        readOnly: !isAdmin,
        key: const Key('companyName'),
        decoration: InputDecoration(labelText: localizations.companyName),
        controller: _nameController,
        validator: (value) {
          if (value!.isEmpty) return localizations.companyNameError;
          return null;
        },
      ),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: const Key('telephoneNr'),
              decoration: InputDecoration(labelText: localizations.telephoneNr),
              controller: _telephoneController,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AutocompleteLabel<Currency>(
              key: const Key('currency'),
              label: localizations.currency,
              initialValue: _selectedCurrency,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return currencies;
                return currencies.where(
                  (Currency c) => '${c.description} [${c.currencyId}]'
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()),
                );
              },
              displayStringForOption: (Currency c) =>
                  '${c.description} [${c.currencyId}]',
              onSelected: (Currency? newValue) {
                setState(() {
                  _selectedCurrency = newValue ?? _selectedCurrency;
                });
              },
              validator: (value) => null,
            ),
          ),
        ],
      ),
      TextFormField(
        readOnly: !isAdmin,
        key: const Key('email'),
        decoration: InputDecoration(labelText: localizations.emailAddress),
        controller: _emailController,
        validator: (value) {
          if (value != null &&
              value.isNotEmpty &&
              !RegExp(
                r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
              ).hasMatch(value)) {
            return localizations.emailInvalid;
          }
          return null;
        },
      ),
      TextFormField(
        readOnly: !isAdmin,
        key: const Key('url'),
        decoration: InputDecoration(labelText: localizations.webAddress),
        controller: _urlController,
      ),
      if (company.role == Role.company)
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('vatPerc'),
                readOnly: !isAdmin,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: localizations.vatPercentage,
                ),
                controller: _vatPercController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: const Key('salesPerc'),
                readOnly: !isAdmin,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: localizations.salesTaxPercentage,
                ),
                controller: _salesPercController,
              ),
            ),
          ],
        ),
      GroupingDecorator(
        labelText: localizations.postalAddress,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: const Key('address'),
                onTap: () async {
                  var result = await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return AddressDialog(address: company.address);
                    },
                  );
                  if (!mounted) return;
                  if (result is Address) {
                    setState(() {
                      company = company.copyWith(address: result);
                    });
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        company.address?.address1 != null &&
                                company.address?.address2 != "_DELETE_"
                            ? "${company.address?.city} "
                                  "${company.address?.country ?? ''}"
                            : localizations.noPostalAddress,
                        key: const Key('addressLabel'),
                      ),
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
                                ? () => setState(
                                    () => company = company.copyWith(
                                      address: company.address!.copyWith(
                                        address2: "_DELETE_",
                                      ),
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      GroupingDecorator(
        labelText: localizations.paymentMethod,
        child: Row(
          children: [
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
                              paymentMethod: company.paymentMethod,
                            );
                          },
                        );
                        if (!mounted) return;
                        if (result is PaymentMethod) {
                          setState(() {
                            company = company.copyWith(paymentMethod: result);
                          });
                        }
                      }
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        company.paymentMethod != null &&
                                company.paymentMethod?.ccDescription !=
                                    "_DELETE_"
                            ? "${company.paymentMethod?.ccDescription}"
                            : "${localizations.noPaymentMethod}"
                                  "${company.address == null ? ", ${localizations.needPostalAddress}" : ""}",
                        key: const Key('paymentMethodLabel'),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.arrow_drop_down),
                        const SizedBox(width: 10),
                        if (company.paymentMethod != null &&
                            company.paymentMethod?.ccDescription != "_DELETE_")
                          IconButton(
                            key: const Key('deletePaymentMethod'),
                            onPressed: isAdmin && company.paymentMethod != null
                                ? () => setState(
                                    () => company = company.copyWith(
                                      paymentMethod: company.paymentMethod!
                                          .copyWith(ccDescription: "_DELETE_"),
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (company.role == Role.company)
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: !isAdmin,
                key: const Key('hostName'),
                decoration: InputDecoration(labelText: localizations.hostName),
                controller: _hostNameController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                readOnly: !isAdmin,
                key: const Key('secondaryBackend'),
                decoration: InputDecoration(
                  labelText: localizations.secondaryBackend,
                ),
                controller: _backendController,
              ),
            ),
          ],
        ),
    ];

    Widget updateButton = Row(
      children: [
        Expanded(
          child: Visibility(
            visible: isAdmin,
            child: OutlinedButton(
              key: const Key('companyDialogUpdate'),
              onPressed: isAdmin
                  ? () async {
                      if (_companyDialogFormKey.currentState!.validate()) {
                        Company updatedCompany = Company(
                          partyId: company.partyId,
                          pseudoId: _idController.text,
                          email: _emailController.text,
                          url: _urlController.text,
                          name: _nameController.text,
                          role: _selectedRole,
                          telephoneNr: _telephoneController.text,
                          currency: _selectedCurrency,
                          address: company.address,
                          paymentMethod: company.paymentMethod,
                          vatPerc: Decimal.parse(
                            _vatPercController.text.isEmpty
                                ? '0'
                                : _vatPercController.text,
                          ),
                          salesPerc: Decimal.parse(
                            _salesPercController.text.isEmpty
                                ? '0'
                                : _salesPercController.text,
                          ),
                          hostName: _hostNameController.text,
                          secondaryBackend: _backendController.text,
                          image: await HelperFunctions.getResizedImage(
                            _imageFile?.path,
                          ),
                        );
                        if (!mounted) return;
                        if (_imageFile?.path != null &&
                            updatedCompany.image == null) {
                          HelperFunctions.showMessage(
                            context,
                            'Image upload error!',
                            Colors.red,
                          );
                        } else {
                          companyUserBloc.add(
                            CompanyUserUpdate(
                              CompanyUser.tryParse(updatedCompany),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: Text(
                company.partyId == null
                    ? localizations.create
                    : localizations.update,
              ),
            ),
          ),
        ),
      ],
    );

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: widgets[i++],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: i < widgets.length ? widgets[i] : Container(),
                ),
              ),
            ],
          ),
        );
      }
    }
    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(padding: const EdgeInsets.all(5), child: widgets[i]));
    }

    return CompanyForm(
      key: const Key('CompanyForm'),
      companyDialogFormKey: _companyDialogFormKey,
      scrollController: _scrollController,
      company: company,
      imageFile: _imageFile,
      rows: rows,
      column: column,
      updateButton: updateButton,
      widget: widget,
      employeeChips: employeeChips,
      localizations: localizations,
      onUploadTap: () async {
        final pickedFile = await HelperFunctions.pickImage();
        if (pickedFile != null) {
          setState(() {
            _imageFile = pickedFile;
          });
        }
      },
      onRemove: (_imageFile != null || company.image != null)
          ? () {
              setState(() {
                _imageFile = null;
              });
            }
          : null,
    );
  }
}

class CompanyForm extends StatelessWidget {
  const CompanyForm({
    super.key,
    required GlobalKey<FormState> companyDialogFormKey,
    required ScrollController scrollController,
    required this.company,
    required XFile? imageFile,
    required this.rows,
    required this.column,
    required this.updateButton,
    required this.widget,
    required this.employeeChips,
    required this.localizations,
    this.onUploadTap,
    this.onRemove,
  }) : _companyDialogFormKey = companyDialogFormKey,
       _scrollController = scrollController,
       _imageFile = imageFile;

  final GlobalKey<FormState> _companyDialogFormKey;
  final ScrollController _scrollController;
  final Company company;
  final XFile? _imageFile;
  final List<Widget> rows;
  final List<Widget> column;
  final Widget updateButton;
  final CompanyDialog widget;
  final List<Widget> employeeChips;
  final UserCompanyLocalizations localizations;
  final VoidCallback? onUploadTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _companyDialogFormKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const Key('companyDialogListView'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
          child: Column(
            children: [
              StyledImageUpload(
                label: 'Company Logo',
                subtitle: 'Click to upload. JPG, PNG up to 2MB',
                image: _imageFile != null
                    ? (kIsWeb
                          ? NetworkImage(_imageFile!.path)
                          : FileImage(File(_imageFile!.path)))
                    : null,
                imageBytes: _imageFile == null ? company.image : null,
                fallbackText: company.name != null
                    ? company.name!.substring(0, 1)
                    : '?',
                onUploadTap: onUploadTap,
                onRemove: onRemove,
              ),
              const SizedBox(height: 10),
              Column(children: (rows.isEmpty ? column : rows)),
              updateButton,
              if (widget.dialog) const SizedBox(height: 10),
              if (widget.dialog)
                GroupingDecorator(
                  labelText: localizations.employees,
                  child: Wrap(spacing: 10, children: employeeChips),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
