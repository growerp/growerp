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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_inventory.dart';

class LocationDialog extends StatefulWidget {
  final Location location;
  const LocationDialog(this.location, {super.key});
  @override
  LocationDialogState createState() => LocationDialogState();
}

class LocationDialogState extends State<LocationDialog> {
  late Location location;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pseudoIdController = TextEditingController();
  final TextEditingController _qohController = TextEditingController();
  Decimal qohTotal = Decimal.zero;
  late InventoryLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    location = widget.location;
    _nameController.text = location.locationName ?? '';
    _pseudoIdController.text = location.pseudoId ?? '';
    for (Asset asset in location.assets) {
      qohTotal += asset.quantityOnHand ?? Decimal.zero;
    }
    _qohController.text = qohTotal.toString();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = InventoryLocalizations.of(context)!;
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('LocationDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) async {
          switch (state.status) {
            case LocationStatus.success:
              HelperFunctions.showMessage(
                context,
                location.locationId == null
                    ? _localizations.addSuccess
                    : _localizations.updateSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
              break;
            case LocationStatus.failure:
              HelperFunctions.showMessage(
                context,
                _localizations.error(state.message ?? ''),
                Colors.red,
              );
              break;
            default:
              const Text("????");
          }
        },
        child: popUp(
          context: context,
          child: _showForm(isPhone),
          title: _localizations.locationInfo(
            location.pseudoId ?? _localizations.newLabel,
          ),
          height: 400,
          width: 400,
        ),
      ),
    );
  }

  Widget _showForm(bool isPhone) {
    return Center(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('listView'),
          children: <Widget>[
            TextFormField(
              key: const Key('id'),
              decoration: InputDecoration(labelText: _localizations.locationId),
              controller: _pseudoIdController,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('name'),
              decoration: InputDecoration(
                labelText: _localizations.locationName,
              ),
              controller: _nameController,
              validator: (value) {
                if (value!.isEmpty) {
                  return _localizations.enterLocationName;
                }
                return null;
              },
            ),
            if (location.locationId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                child: TextFormField(
                  readOnly: true, // total of assets can not be updated here
                  controller: _qohController,
                  key: const Key('qoh'),
                  decoration: InputDecoration(
                    labelText: _localizations.quantityOnHand,
                    enabled: false,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('update'),
              child: Text(
                location.locationId == null
                    ? _localizations.create
                    : _localizations.update,
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  context.read<LocationBloc>().add(
                    LocationUpdate(
                      Location(
                        locationId: location.locationId,
                        pseudoId: _pseudoIdController.text,
                        locationName: _nameController.text,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
