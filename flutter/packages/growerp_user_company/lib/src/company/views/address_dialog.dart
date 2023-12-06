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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

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
          width: 350,
          child: _editAddress(context)),
    );
  }

  Widget _editAddress(BuildContext context) {
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
                      decoration: const InputDecoration(labelText: 'Country'),
                      controller: _countrySearchBoxController,
                    ),
                    title: popUp(
                      context: context,
                      title: 'Select country',
                      height: 50,
                    ),
                  ),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration:
                          InputDecoration(labelText: 'Country')),
                  itemAsString: (Country? u) => " ${u!.name}",
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
                          child: Text(
                              widget.address == null ? 'Create' : 'Update'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.of(context).pop(Address(
                                  address1: _address1Controller.text,
                                  address2: _address2Controller.text,
                                  postalCode: _postalCodeController.text,
                                  city: _cityController.text,
                                  province: _provinceController.text,
                                  country: _selectedCountry?.name));
                            }
                          }))
                ]),
              ],
            )));
  }
}
