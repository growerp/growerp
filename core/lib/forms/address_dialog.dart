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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';

class AddressDialog extends StatefulWidget {
  final Address? address;
  final Key? key;
  const AddressDialog({this.address, this.key}) : super(key: key);
  @override
  _AddressState createState() => _AddressState(address, key);
}

class _AddressState extends State<AddressDialog> {
  final Address? address;
  final Key? key;
  TextEditingController _address1Controller = TextEditingController();
  TextEditingController _address2Controller = TextEditingController();
  TextEditingController _postalCodeController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _provinceController = TextEditingController();
  TextEditingController _countrySearchBoxController = TextEditingController();
  Country? _selectedCountry;

  final _formKey = GlobalKey<FormState>();

  _AddressState(this.address, this.key);

  @override
  void initState() {
    super.initState();
    if (address != null) {
      _address1Controller.text = address!.address1 ?? '';
      _address2Controller.text = address!.address2 ?? '';
      _postalCodeController.text = address!.postalCode ?? '';
      _cityController.text = address!.city ?? '';
      _provinceController.text = address!.province ?? '';
      _selectedCountry =
          countries.firstWhere((element) => element.name == address!.country);
    }
  }

  @override
  Widget build(BuildContext context) {
    var repos = context.read<Object>();

    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: GestureDetector(
            onTap: () {},
            child: Dialog(
                key: Key('AddressDialog'),
                insetPadding: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                    height: 700,
                    width: 400,
                    child: _editAddress(context, repos)))));
  }

  Widget _editAddress(BuildContext context, repos) {
    return Center(
        child: Container(
            width: 300,
            child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    SizedBox(height: 30),
                    Center(
                        child: Text(
                            (address == null
                                ? "New Company Address"
                                : "Company Address #${address!.addressId}"),
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.bold))),
                    SizedBox(height: 20),
                    TextFormField(
                      key: Key('address1'),
                      decoration: InputDecoration(labelText: 'Address line 1'),
                      controller: _address1Controller,
                      validator: (value) {
                        if (value!.isEmpty)
                          return 'Please enter a Street name?';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      key: Key('address2'),
                      decoration: InputDecoration(labelText: 'Address line 2'),
                      controller: _address2Controller,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      key: Key('postal'),
                      decoration: InputDecoration(labelText: 'PostalCode'),
                      controller: _postalCodeController,
                      validator: (value) {
                        if (value!.isEmpty)
                          return 'Please enter a Postal Code?';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      key: Key('city'),
                      decoration: InputDecoration(labelText: 'City'),
                      controller: _cityController,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter a City?';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      key: Key('province'),
                      decoration: InputDecoration(labelText: 'Province/State'),
                      controller: _provinceController,
                      validator: (value) {
                        if (value!.isEmpty)
                          return 'Please enter a Province or State?';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    DropdownSearch<Country>(
                      label: 'Country',
                      dialogMaxWidth: 300,
                      autoFocusSearchBox: true,
                      selectedItem: _selectedCountry,
                      dropdownSearchDecoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                      ),
                      searchBoxDecoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                      ),
                      showSearchBox: true,
                      itemAsString: (Country? u) => "${u!.name}",
                      searchBoxController: _countrySearchBoxController,
                      items: countries,
                      validator: (value) {
                        if (value == null) return 'Please Select a country?';
                        return null;
                      },
                      onChanged: (Country? newValue) {
                        _selectedCountry = newValue;
                      },
                    ),
                    SizedBox(height: 20),
                    Row(children: [
                      ElevatedButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                      SizedBox(width: 20),
                      Expanded(
                          child: ElevatedButton(
                        key: Key('updateAddress'),
                        child: Text('Update'),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.of(context).pop(Address(
                              address1: _address1Controller.text,
                              address2: _address2Controller.text,
                              postalCode: _postalCodeController.text,
                              city: _cityController.text,
                              province: _provinceController.text,
                              country: _selectedCountry != null
                                  ? _selectedCountry!.name
                                  : null,
                            ));
                          }
                        },
                      )),
                    ]),
                  ],
                ))));
  }
}
