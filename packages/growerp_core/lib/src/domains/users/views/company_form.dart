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
import '../../common/functions/helper_functions.dart';
import '../../../templates/templates.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domains.dart';
import 'package:responsive_framework/responsive_framework.dart';

class CompanyForm extends StatefulWidget {
  const CompanyForm({super.key});

  @override
  CompanyPageState createState() => CompanyPageState();
}

class CompanyPageState extends State<CompanyForm> {
  final _formKey = GlobalKey<FormState>();
  late Authenticate authenticate;
  late Company company;
  late User user;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vatPercController = TextEditingController();
  final TextEditingController _salesPercController = TextEditingController();
  late Currency _selectedCurrency;
  late bool isAdmin;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    authenticate = context.read<AuthBloc>().state.authenticate!;
    company = authenticate.company!;
    user = authenticate.user!;
    isAdmin = authenticate.user!.userGroup == UserGroup.admin;
    _selectedCurrency = currencies.firstWhere(
        (element) => element.currencyId == company.currency?.currencyId);
    _nameController.text = company.name!;
    _emailController.text = company.email ?? '';
    _vatPercController.text =
        company.vatPerc == null ? '' : company.vatPerc.toString();
    _salesPercController.text =
        company.salesPerc == null ? '' : company.salesPerc.toString();
    if (company.telephoneNr != null) {
      _telephoneController.text = company.telephoneNr!;
    }
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
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      switch (state.status) {
        case AuthStatus.authenticated:
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
          break;
        case AuthStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
      }
    }, builder: (context, state) {
      switch (state.status) {
        case AuthStatus.failure:
          return Center(
              child: Text('failed to fetch company info ${state.message}'));
        case AuthStatus.authenticated:
          authenticate = state.authenticate!;
          company = authenticate.company!;
          user = authenticate.user!;
          return Scaffold(
              floatingActionButton:
                  imageButtons(context, _onImageButtonPressed),
              body: Center(
                  child:
                      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                          ? FutureBuilder<void>(
                              future: retrieveLostData(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<void> snapshot) {
                                if (snapshot.hasError) {
                                  return Text(
                                    'Pick image error: ${snapshot.error}}',
                                    textAlign: TextAlign.center,
                                  );
                                }
                                return _showForm(isAdmin, company, state);
                              })
                          : _showForm(isAdmin, company, state)));
        default:
          return const LoadingIndicator();
      }
    });
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(bool isAdmin, Company company, AuthState state) {
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
      TextFormField(
        readOnly: !isAdmin,
        key: const Key('email'),
        decoration: const InputDecoration(labelText: 'Company Email address'),
        controller: _emailController,
        validator: (value) {
          if (value!.isEmpty) return 'Please enter Email address?';
          if (!RegExp(
                  r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
              .hasMatch(value)) {
            return 'This is not a valid email';
          }
          return null;
        },
      ),
      TextFormField(
        key: const Key('telephoneNr'),
        decoration: const InputDecoration(labelText: 'Telephone number'),
        controller: _telephoneController,
      ),
      DropdownButtonFormField<Currency>(
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
      Row(children: [
        Expanded(
            child: Text(
                company.address != null
                    ? "${company.address?.city} "
                        "${company.address?.country!}"
                    : "No postal address yet",
                key: const Key('addressLabel'))),
        SizedBox(
            width: 100,
            child: ElevatedButton(
              key: const Key('address'),
              onPressed: isAdmin
                  ? () async {
                      var result = await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return AddressDialog(address: company.address);
                          });
                      if (!mounted) return;
                      if (result is Address) {
                        context.read<AuthBloc>().add(AuthUpdateCompany(
                            company.copyWith(address: result)));
                      }
                    }
                  : null,
              child:
                  Text("${company.address != null ? 'Update' : 'Add'} Address"),
            ))
      ]),
      Row(children: [
        Expanded(
            child: Text(
                company.paymentMethod != null
                    ? "${company.paymentMethod?.ccDescription}"
                    : "No payment methods yet",
                key: const Key('paymentMethodLabel'))),
        SizedBox(
            width: 100,
            child: ElevatedButton(
                key: const Key('paymentMethod'),
                onPressed: isAdmin
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
                          context.read<AuthBloc>().add(AuthUpdateCompany(
                              company.copyWith(paymentMethod: result)));
                        }
                      }
                    : null,
                child: Text(
                    '${company.paymentMethod != null ? 'Update' : 'Add'} Payment Method')))
      ]),
    ];

    Widget update = Row(children: [
      Expanded(
          child: Visibility(
              visible: isAdmin,
              child: ElevatedButton(
                  key: const Key('update'),
                  onPressed: isAdmin
                      ? () async {
                          if (_formKey.currentState!.validate()) {
                            company = Company(
                                partyId: company.partyId,
                                email: _emailController.text,
                                name: _nameController.text,
                                telephoneNr: _telephoneController.text,
                                currency: _selectedCurrency,
                                address: company.address,
                                paymentMethod:
                                    authenticate.company?.paymentMethod,
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
                                  .read<AuthBloc>()
                                  .add(AuthUpdateCompany(company));
                            }
                          }
                        }
                      : null,
                  child: Text(
                    company.partyId == null ? 'Create' : 'Update',
                  ))))
    ]);

    List<Widget> rows = [];
    if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET)) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10), child: widgets[i++])),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: i < widgets.length ? widgets[i] : Container()))
          ],
        ));
      }
    }
    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(padding: const EdgeInsets.all(10), child: widgets[i]));
    }

    return Center(
        child: SingleChildScrollView(
            key: const Key('listView'),
            child: Form(
                key: _formKey,
                child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(children: [
                      Center(
                          child: Text(
                        'id:#${company.partyId}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                        key: const Key('header'),
                      )),
                      const SizedBox(height: 10),
                      CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 80,
                          child: _imageFile != null
                              ? kIsWeb
                                  ? Image.network(_imageFile!.path, scale: 0.3)
                                  : Image.file(File(_imageFile!.path),
                                      scale: 0.3)
                              : company.image != null
                                  ? Image.memory(company.image!, scale: 0.3)
                                  : Text(
                                      company.name!.isNotEmpty
                                          ? company.name!.substring(0, 1)
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 30, color: Colors.black))),
                      const SizedBox(height: 10),
                      Column(children: (rows.isEmpty ? column : rows)),
                      update,
                    ])))));
  }
}
