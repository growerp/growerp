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

import '../../common/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import '../../domains.dart';
import '../../../api_repository.dart';

class LocationDialog extends StatefulWidget {
  final Location location;
  LocationDialog(this.location);
  @override
  _LocationState createState() => _LocationState(location);
}

class _LocationState extends State<LocationDialog> {
  final Location location;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();

  _LocationState(this.location);

  @override
  void initState() {
    super.initState();
    _nameController.text = location.locationName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    var repos = context.read<APIRepository>();
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: Key('LocationDialog'),
                    insetPadding: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocListener<LocationBloc, LocationState>(
                        listener: (context, state) async {
                          switch (state.status) {
                            case LocationStatus.success:
                              HelperFunctions.showMessage(
                                  context,
                                  '${location.locationId == null ? "Add" : "Update"} successfull',
                                  Colors.green);
                              await Future.delayed(Duration(milliseconds: 500));
                              Navigator.of(context).pop();
                              break;
                            case LocationStatus.failure:
                              HelperFunctions.showMessage(context,
                                  'Error: ${state.message}', Colors.red);
                              break;
                            default:
                              Text("????");
                          }
                        },
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              padding: EdgeInsets.all(20),
                              width: 400,
                              height: 200,
                              child: Center(
                                child: _showForm(repos, isPhone),
                              )),
                          Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget _showForm(repos, isPhone) {
    return Center(
        child: Container(
            child: Form(
                key: _formKey,
                child: ListView(key: Key('listView'), children: <Widget>[
                  Center(
                      child: Text(
                          location.locationId == null
                              ? "New"
                              : "${location.locationId}",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold))),
                  SizedBox(height: 30),
                  TextFormField(
                    key: Key('name'),
                    decoration: InputDecoration(labelText: 'Location Name'),
                    controller: _nameController,
                    validator: (value) {
                      if (value!.isEmpty)
                        return 'Please enter a location name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      key: Key('update'),
                      child: Text(
                          location.locationId == null ? 'Create' : 'Update'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          context.read<LocationBloc>().add(LocationUpdate(
                                Location(
                                  locationId: location.locationId,
                                  locationName: _nameController.text,
                                ),
                              ));
                        }
                      }),
                ]))));
  }
}
