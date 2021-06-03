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
import 'package:core/forms/fatalError_form.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:models/@models.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import '../blocs/@blocs.dart';
import '../helper_functions.dart';
import '../templates/@templates.dart';

class CompanyInfoForm extends StatelessWidget {
  final FormArguments formArguments;
  CompanyInfoForm(this.formArguments);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated)
        return CompanyPage(formArguments.message, state.authenticate);
      return FatalErrorForm("Should be logged in!");
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _vatPercController = TextEditingController();
  final _salesPercController = TextEditingController();
  late Company updatedCompany;
  late Currency _selectedCurrency;
  late bool isAdmin;
  Country? _selectedCountry;
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
    updatedCompany = authenticate.company!;
    isAdmin = (authenticate.user!.userGroupId == "GROWERP_M_ADMIN");

    _selectedCurrency = currencies.firstWhere(
        (element) => element.currencyId == updatedCompany.currencyId);
    _nameController..text = updatedCompany.name!;
    _emailController..text = updatedCompany.email!;
    if (updatedCompany.address != null) {
      _address1Controller..text = updatedCompany.address!.address1!;
      _address2Controller..text = updatedCompany.address!.address2!;
      _provinceController..text = updatedCompany.address!.province!;
      _cityController..text = updatedCompany.address!.city!;
      _postalCodeController..text = updatedCompany.address!.postalCode!;
      _selectedCountry = updatedCompany.address!.country == null
          ? Country()
          : countries.firstWhere(
              (element) => element.id == updatedCompany.address!.country!);
    }
    _vatPercController
      ..text = updatedCompany.vatPerc.toString() == "0"
          ? ''
          : updatedCompany.vatPerc.toString();
    _salesPercController
      ..text = updatedCompany.salesPerc.toString() == "0"
          ? ''
          : updatedCompany.salesPerc.toString();
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
    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
            floatingActionButton: imageButtons(context, _onImageButtonPressed),
            body: BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
              if (state is AuthAuthenticated) {
                HelperFunctions.showMessage(
                    context, '${state.message}', Colors.green);
              }
              if (state is AuthProblem) {
                HelperFunctions.showMessage(
                    context, '${state.errorMessage}', Colors.red);
              }
              if (state is AuthLoading) {
                HelperFunctions.showMessage(
                    context, '${state.message}', Colors.green);
              }
            }, builder: (context, state) {
              return Center(
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
                              return _showForm(
                                  authenticate, isAdmin, updatedCompany);
                            })
                        : _showForm(authenticate, isAdmin, updatedCompany),
              );
            })));
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(
      Authenticate authenticate, bool isAdmin, Company updatedCompany) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
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
    int columns = isPhone ? 1 : 2;
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, updatedCompany);
          return false;
        },
        child: Center(
            child: Container(
                width: columns.toDouble() * 400,
                child: Form(
                    key: _formKey,
                    child: Padding(
                        padding: EdgeInsets.all(15),
                        child: GridView.count(
                            crossAxisCount: columns,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: (5.5),
                            children: <Widget>[
                              CircleAvatar(
                                  backgroundColor: Colors.green,
                                  radius: 80,
                                  child: _imageFile != null
                                      ? kIsWeb
                                          ? Image.network(_imageFile!.path)
                                          : Image.file(File(_imageFile!.path))
                                      : updatedCompany.image != null
                                          ? Image.memory(updatedCompany.image!)
                                          : Text(
                                              updatedCompany.name!
                                                  .substring(0, 1),
                                              style: TextStyle(
                                                  fontSize: 30,
                                                  color: Colors.black))),
                              TextFormField(
                                readOnly: !isAdmin,
                                key: Key('companyName'),
                                decoration:
                                    InputDecoration(labelText: 'Company Name'),
                                controller: _nameController,
                                validator: (value) {
                                  if (value!.isEmpty)
                                    return 'Please enter the company Name?';
                                  return null;
                                },
                              ),
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
                              IgnorePointer(
                                  ignoring: !isAdmin,
                                  child: Container(
                                    width: 400,
                                    height: 60,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25.0),
                                      border: Border.all(
                                          color: Colors.grey,
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
                              TextFormField(
                                readOnly: !isAdmin,
                                decoration:
                                    InputDecoration(labelText: 'Address1'),
                                controller: _address1Controller,
                              ),
                              TextFormField(
                                readOnly: !isAdmin,
                                decoration:
                                    InputDecoration(labelText: 'Address2'),
                                controller: _address2Controller,
                              ),
                              TextFormField(
                                readOnly: !isAdmin,
                                decoration:
                                    InputDecoration(labelText: 'PostalCode'),
                                controller: _postalCodeController,
                                validator: (value) {
                                  if (_address1Controller.text.isNotEmpty &&
                                      value!.isEmpty)
                                    return 'Please enter a Postal Code?';
                                  return null;
                                },
                              ),
                              TextFormField(
                                readOnly: !isAdmin,
                                decoration: InputDecoration(labelText: 'City'),
                                controller: _cityController,
                                validator: (value) {
                                  if (_address1Controller.text.isNotEmpty &&
                                      value!.isEmpty)
                                    return 'Please enter a City?';
                                  return null;
                                },
                              ),
                              TextFormField(
                                readOnly: !isAdmin,
                                decoration: InputDecoration(
                                    labelText: 'Province',
                                    contentPadding: new EdgeInsets.symmetric(
                                        vertical: 30.0, horizontal: 10.0)),
                                controller: _provinceController,
                                validator: (value) {
                                  if (_address1Controller.text.isNotEmpty &&
                                      value!.isEmpty)
                                    return 'Please enter a Province?';
                                  return null;
                                },
                              ),
                              IgnorePointer(
                                  ignoring: !isAdmin,
                                  child: Container(
                                      width: 400,
                                      height: 40,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                        border: Border.all(
                                            color: Colors.grey,
                                            style: BorderStyle.solid,
                                            width: 0.80),
                                      ),
                                      child: DropdownButton<Country>(
                                        key: Key('dropDown'),
                                        underline:
                                            SizedBox(), // remove underline
                                        hint: Text('Country'),
                                        value: _selectedCountry,
                                        items: countries.map((item) {
                                          return DropdownMenuItem<Country>(
                                              child: Text(item.name!),
                                              value: item);
                                        }).toList(),
                                        onChanged: (Country? newValue) {
                                          setState(() {
                                            _selectedCountry = newValue;
                                          });
                                        },
                                        isExpanded: true,
                                      ))),
                              TextFormField(
                                readOnly: !isAdmin,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: InputDecoration(
                                    labelText: 'VAT. percentage'),
                                controller: _vatPercController,
                              ),
                              TextFormField(
                                readOnly: !isAdmin,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: InputDecoration(
                                    labelText: 'Sales Tax percentage'),
                                controller: _salesPercController,
                              ),
                              Visibility(
                                  visible: isAdmin,
                                  child: ElevatedButton(
                                      key: Key('update'),
                                      child: Text(updatedCompany.partyId == null
                                          ? 'Create'
                                          : 'Update'),
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          //        && !Loading)
                                          Address? address;
                                          if (_address1Controller
                                              .text.isNotEmpty)
                                            Address? address = Address(
                                              address1:
                                                  _address1Controller.text,
                                              address2:
                                                  _address2Controller.text,
                                              city: _cityController.text,
                                              postalCode:
                                                  _postalCodeController.text,
                                              province:
                                                  _provinceController.text,
                                              country: _selectedCountry!.id,
                                            );
                                          updatedCompany = Company(
                                              partyId: updatedCompany.partyId,
                                              email: _emailController.text,
                                              name: _nameController.text,
                                              currencyId:
                                                  _selectedCurrency.currencyId,
                                              address: address,
                                              vatPerc: Decimal.parse(
                                                  _vatPercController
                                                          .text.isEmpty
                                                      ? '0'
                                                      : _vatPercController
                                                          .text),
                                              salesPerc: Decimal.parse(
                                                  _salesPercController
                                                          .text.isEmpty
                                                      ? '0'
                                                      : _salesPercController
                                                          .text),
                                              image: await HelperFunctions
                                                  .getResizedImage(
                                                      _imageFile?.path));
                                          BlocProvider.of<AuthBloc>(context)
                                              .add(UpdateCompany(authenticate,
                                                  updatedCompany));
                                        }
                                      }))
                            ]))))));
  }
}
