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
import '../../domains.dart';

import '../../../api_repository.dart';

class AddressDialog extends StatefulWidget {
  final Address? address;
  const AddressDialog({super.key, this.address});
  @override
  AddressDialogState createState() => AddressDialogState();
}

class AddressDialogState extends State<AddressDialog> {
  late Address? address;
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _countrySearchBoxController =
      TextEditingController();
  Country? _selectedCountry;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    address = widget.address;
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
    var repos = context.read<APIRepository>();

    return Dialog(
      key: const Key('AddressDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: popUp(
          context: context,
          title: address == null
              ? "New Company Address"
              : "Company Address #${address!.addressId}",
          height: 700,
          width: 400,
          child: _editAddress(context, repos)),
    );
  }

  Widget _editAddress(BuildContext context, repos) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            key: const Key('listView'),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('address1'),
                  decoration:
                      const InputDecoration(labelText: 'Address line 1'),
                  controller: _address1Controller,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a Street name?';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('address2'),
                  decoration:
                      const InputDecoration(labelText: 'Address line 2'),
                  controller: _address2Controller,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('postalCode'),
                  decoration: const InputDecoration(labelText: 'PostalCode'),
                  controller: _postalCodeController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a Postal Code?';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('city'),
                  decoration: const InputDecoration(labelText: 'City'),
                  controller: _cityController,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter a City?';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('province'),
                  decoration:
                      const InputDecoration(labelText: 'Province/State'),
                  controller: _provinceController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a Province or State?';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownSearch<Country>(
                  key: const Key('country'),
                  selectedItem: _selectedCountry,
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      autofocus: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                      ),
                      controller: _countrySearchBoxController,
                    ),
                    menuProps:
                        MenuProps(borderRadius: BorderRadius.circular(20.0)),
                    title: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColorDark,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            )),
                        child: const Center(
                            child: Text('Select country',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )))),
                  ),
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0)),
                  ),
                  itemAsString: (Country? u) => u!.name,
                  items: countries,
                  validator: (value) {
                    if (value == null) {
                      return 'Please Select a country?';
                    }
                    return null;
                  },
                  onChanged: (Country? newValue) {
                    _selectedCountry = newValue;
                  },
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: ElevatedButton(
                          key: const Key('updateAddress'),
                          child: const Text('Update'),
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
                          }))
                ]),
              ],
            )));
  }
}
