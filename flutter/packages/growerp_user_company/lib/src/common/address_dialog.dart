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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';

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
      if (address?.country != null && countries.isNotEmpty) {
        _selectedCountry = countries.firstWhere(
          (element) => element.name == address!.country,
        );
      } else {
        _selectedCountry = Country(id: "USA", name: "United States");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = UserCompanyLocalizations.of(context)!;
    return Dialog(
      key: const Key('AddressDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: address == null
            ? localizations.newCompanyAddress
            : localizations.companyAddressDetail(address!.addressId!),
        height: 700,
        width: 350,
        child: _editAddress(localizations),
      ),
    );
  }

  Widget _editAddress(UserCompanyLocalizations localizations) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const Key('addressListView'),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('address1'),
              decoration: InputDecoration(labelText: localizations.address1),
              controller: _address1Controller,
              validator: (value) {
                if (value!.isEmpty) {
                  return localizations.address1Error;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('address2'),
              decoration: InputDecoration(labelText: localizations.address2),
              controller: _address2Controller,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('postalCode'),
              decoration: InputDecoration(labelText: localizations.postalCode),
              controller: _postalCodeController,
              validator: (value) {
                if (value!.isEmpty) {
                  return localizations.postalCodeError;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('city'),
              decoration: InputDecoration(labelText: localizations.city),
              controller: _cityController,
              validator: (value) {
                if (value!.isEmpty) return localizations.cityError;
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('province'),
              decoration: InputDecoration(labelText: localizations.province),
              controller: _provinceController,
              validator: (value) {
                if (value!.isEmpty) {
                  return localizations.provinceError;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AutocompleteLabel<Country>(
              key: const Key('country'),
              label: localizations.country,
              initialValue: _selectedCountry,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return countries;
                return countries.where(
                  (Country c) => c.name.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              displayStringForOption: (Country u) => " ${u.name}",
              onSelected: (Country? newValue) {
                _selectedCountry = newValue;
              },
              validator: (value) {
                if (value == null) {
                  return localizations.countryError;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('updateAddress'),
                    child: Text(
                      widget.address == null
                          ? localizations.create
                          : localizations.update,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(context).pop(
                          Address(
                            address1: _address1Controller.text,
                            address2: _address2Controller.text,
                            postalCode: _postalCodeController.text,
                            city: _cityController.text,
                            province: _provinceController.text,
                            country: _selectedCountry?.name,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
