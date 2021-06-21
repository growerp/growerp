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
import 'package:core/widgets/loading_indicator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:models/@models.dart';
import '../blocs/@blocs.dart';
import '../helper_functions.dart';
import '../templates/@templates.dart';
import 'address_dialog.dart';

class CompanyInfoForm extends StatelessWidget {
  final FormArguments formArguments;
  CompanyInfoForm(this.formArguments);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated)
        return CompanyPage(formArguments.message, state.authenticate);
      if (state is AuthAuthenticated) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
      return LoadingIndicator();
    });
  }
}

class CompanyPage extends StatefulWidget {
  final String? message;
  final Authenticate authenticate;
  CompanyPage(this.message, this.authenticate);

  @override
  _CompanyState createState() => _CompanyState(message, authenticate);
}

class _CompanyState extends State<CompanyPage> {
  final String? message;
  final Authenticate authenticate;
  final _formKey = GlobalKey<FormState>();
  late Company company;
  late User user;
  Address? companyAddress;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _vatPercController = TextEditingController();
  TextEditingController _salesPercController = TextEditingController();
  late Currency _selectedCurrency;
  late bool isAdmin;
  PickedFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  _CompanyState(this.message, this.authenticate) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  @override
  void initState() {
    super.initState();
    company = authenticate.company!;
    user = authenticate.user!;
    companyAddress = authenticate.company!.address;
    isAdmin = authenticate.user!.userGroupId == 'GROWERP_M_ADMIN';
    _selectedCurrency = currencies
        .firstWhere((element) => element.currencyId == company.currencyId);
    _nameController..text = company.name!;
    _emailController..text = company.email!;
    _vatPercController
      ..text =
          company.vatPerc.toString() == "0" ? '' : company.vatPerc.toString();
    _salesPercController
      ..text = company.salesPerc.toString() == "0"
          ? ''
          : company.salesPerc.toString();
  }

  void _onImageButtonPressed(ImageSource source,
      {BuildContext? context}) async {
    try {
      final pickedFile = await _picker.getImage(
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
    final LostData response = await _picker.getLostData();
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
      if (state is AuthAuthenticated) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
      if (state is AuthProblem) {
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      }
      if (state is AuthLoading) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
    }, builder: (context, state) {
      if (state is AuthLoading) return LoadingIndicator();
      if (state is AuthAuthenticated)
        return ScaffoldMessenger(
            key: scaffoldMessengerKey,
            child: Scaffold(
                key: Key('CompanyInfoForm'),
                floatingActionButton:
                    imageButtons(context, _onImageButtonPressed),
                body: Center(
                  child: !kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.android
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
                            return _showForm(authenticate, isAdmin, company);
                          })
                      : _showForm(authenticate, isAdmin, company),
                )));
      else
        return LoadingIndicator();
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

  Widget _showForm(Authenticate authenticate, bool isAdmin, Company company) {
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
    return Center(
        child: Container(
            width: 400,
            child: Form(
                key: _formKey,
                child: Padding(
                    padding: EdgeInsets.all(15),
                    child: ListView(children: <Widget>[
                      CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 80,
                          child: _imageFile != null
                              ? kIsWeb
                                  ? Image.network(_imageFile!.path)
                                  : Image.file(File(_imageFile!.path))
                              : company.image != null
                                  ? Image.memory(company.image!)
                                  : Text(company.name!.substring(0, 1),
                                      style: TextStyle(
                                          fontSize: 30, color: Colors.black))),
                      SizedBox(height: 10),
                      TextFormField(
                        readOnly: !isAdmin,
                        key: Key('companyName'),
                        decoration: InputDecoration(labelText: 'Company Name'),
                        controller: _nameController,
                        validator: (value) {
                          if (value!.isEmpty)
                            return 'Please enter the company Name?';
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        readOnly: !isAdmin,
                        key: Key('email'),
                        decoration: InputDecoration(
                            contentPadding: new EdgeInsets.symmetric(
                                vertical: 30.0, horizontal: 10.0),
                            labelText: 'Company Email address'),
                        controller: _emailController,
                        validator: (value) {
                          if (value!.isEmpty)
                            return 'Please enter Email address?';
                          if (!RegExp(
                                  r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                              .hasMatch(value)) {
                            return 'This is not a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      IgnorePointer(
                          ignoring: !isAdmin,
                          child: Container(
                            width: 400,
                            height: 60,
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.0),
                              border: Border.all(
                                  color: Colors.black45,
                                  style: BorderStyle.solid,
                                  width: 0.80),
                            ),
                            child: DropdownButton<Currency>(
                              key: Key('dropDown'),
                              underline: SizedBox(), // remove underline
                              hint: Text('Currency'),
                              value: _selectedCurrency,
                              items: currencies.map((item) {
                                return DropdownMenuItem<Currency>(
                                    child: Text(item.description!),
                                    value: item);
                              }).toList(),
                              onChanged: (Currency? newValue) {
                                setState(() {
                                  _selectedCurrency = newValue!;
                                });
                              },
                              isExpanded: true,
                            ),
                          )),
                      SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: TextFormField(
                          readOnly: !isAdmin,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration:
                              InputDecoration(labelText: 'VAT. percentage'),
                          controller: _vatPercController,
                        )),
                        SizedBox(width: 10),
                        Expanded(
                            child: TextFormField(
                          readOnly: !isAdmin,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                              labelText: 'Sales Tax percentage'),
                          controller: _salesPercController,
                        ))
                      ]),
                      SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: Text(companyAddress != null
                                ? "${companyAddress!.city!} ${companyAddress!.country!}"
                                : "No address yet")),
                        SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () async {
                                var result = await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddressDialog(
                                          address: companyAddress);
                                    });
                                if (result is Address)
                                  setState(() {
                                    companyAddress = result;
                                  });
                              },
                              child: Text(company.address != null
                                  ? 'Update\nAddress'
                                  : 'Add\nAddress'),
                            ))
                      ]),
                      SizedBox(height: 10),
                      Visibility(
                          visible: isAdmin,
                          child: ElevatedButton(
                              key: Key('update'),
                              child: Text(company.partyId == null
                                  ? 'Create'
                                  : 'Update'),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  //        && !Loading)
                                  company = Company(
                                      partyId: company.partyId,
                                      email: _emailController.text,
                                      name: _nameController.text,
                                      currencyId: _selectedCurrency.currencyId,
                                      address: companyAddress,
                                      vatPerc: Decimal.parse(
                                          _vatPercController.text.isEmpty
                                              ? '0'
                                              : _vatPercController.text),
                                      salesPerc: Decimal.parse(
                                          _salesPercController.text.isEmpty
                                              ? '0'
                                              : _salesPercController.text),
                                      image:
                                          await HelperFunctions.getResizedImage(
                                              _imageFile?.path));
                                  if (_imageFile?.path != null &&
                                      company.image == null)
                                    HelperFunctions.showMessage(
                                        context,
                                        "Image upload error or larger than 50K",
                                        Colors.red);
                                  else
                                    BlocProvider.of<AuthBloc>(context).add(
                                        UpdateCompany(authenticate, company));
                                }
                              }))
                    ])))));
  }
}
