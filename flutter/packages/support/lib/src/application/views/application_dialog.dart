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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/application_bloc.dart';

class ApplicationDialog extends StatefulWidget {
  final Application application;
  const ApplicationDialog(this.application, {super.key});
  @override
  ApplicationDialogState createState() => ApplicationDialogState();
}

class ApplicationDialogState extends State<ApplicationDialog> {
  final _applicationDialogFormKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _versionController = TextEditingController();
  final _backendUrlController = TextEditingController();
  bool loading = false;
  late Application updatedApplication;
  late ApplicationBloc _applicationBloc;

  @override
  void initState() {
    super.initState();
    _idController.text = widget.application.applicationId;
    _versionController.text = widget.application.version ?? '';
    _backendUrlController.text = widget.application.backendUrl ?? '';
    _applicationBloc = context.read<ApplicationBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicationBloc, ApplicationState>(
      listener: (context, state) async {
        switch (state.status) {
          case ApplicationStatus.success:
            Navigator.of(context).pop();
            break;
          case ApplicationStatus.failure:
            HelperFunctions.showMessage(
              context,
              'Error: ${state.message}',
              Colors.red,
            );
            break;
          default:
        }
      },
      builder: (context, state) {
        if (state.status == ApplicationStatus.loading) {
          return const LoadingIndicator();
        } else {
          return Dialog(
            key: const Key('ApplicationDialog'),
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: popUp(
              context: context,
              child: _showForm(),
              title:
                  'Application #${widget.application.applicationId.isEmpty ? 'New' : widget.application.applicationId}',
              height: 400,
              width: 350,
            ),
          );
        }
      },
    );
  }

  Widget _showForm() {
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Form(
        key: _applicationDialogFormKey,
        child: Column(
          children: [
            const SizedBox(height: 30),
            TextFormField(
              enabled: false,
              key: const Key('Id'),
              decoration: const InputDecoration(labelText: 'Application Id'),
              controller: _idController,
              validator: (value) {
                return value!.isEmpty
                    ? 'Please enter an application id?'
                    : null;
              },
            ),
            TextFormField(
              key: const Key('version'),
              decoration: const InputDecoration(labelText: 'Version'),
              controller: _versionController,
              validator: (value) {
                return value!.isEmpty ? 'Please enter a version?' : null;
              },
            ),
            TextFormField(
              key: const Key('backendUrl'),
              decoration: const InputDecoration(labelText: 'Backend URL'),
              controller: _backendUrlController,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a backend URL?';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              key: const Key('update'),
              child: Text(
                widget.application.applicationId.isEmpty ? 'Create' : 'Update',
              ),
              onPressed: () async {
                if (_applicationDialogFormKey.currentState!.validate()) {
                  _applicationBloc.add(
                    ApplicationUpdate(
                      Application(
                        applicationId: _idController.text,
                        version: _versionController.text,
                        backendUrl: _backendUrlController.text,
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
