/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

class GlAccountFilesDialog extends StatefulWidget {
  const GlAccountFilesDialog({super.key});

  @override
  State<GlAccountFilesDialog> createState() => _FilesHeaderState();
}

class _FilesHeaderState extends State<GlAccountFilesDialog> {
  late GlAccountBloc glAccountBloc;
  late OrderAccountingLocalizations _localizations;
  final _periodYearController = TextEditingController();

  @override
  void initState() {
    glAccountBloc = BlocProvider.of<GlAccountBloc>(context);
    _periodYearController.text = DateTime.now().year.toString();
    super.initState();
  }

  @override
  void dispose() {
    _periodYearController.dispose();
    super.dispose();
  }

  /// Write the ledger CSV where the user picks, so it can be corrected and
  /// uploaded back as the initial balance.
  Future<void> _saveCsv(String csvFile) async {
    try {
      final bytes = foundation.Uint8List.fromList(utf8.encode(csvFile));
      final uri = await FilePicker.saveFile(
        dialogTitle: _localizations.initialUpload,
        fileName: 'GlAccounts.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes, // saveFile writes the bytes itself on every platform
      );
      if (!mounted || uri == null) return; // cancelled
      HelperFunctions.showMessage(context, 'Saved as ${uri.path}', Colors.green);
    } catch (e) {
      if (!mounted) return;
      HelperFunctions.showMessage(context, 'Could not save: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    return BlocConsumer<GlAccountBloc, GlAccountState>(
      listener: (context, state) async {
        if (state.status == GlAccountStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == GlAccountStatus.downloaded) {
          // the dialog stays open: the saved file is meant to be corrected
          // and uploaded back here
          return await _saveCsv(state.csvFile!);
        }
        if (state.status == GlAccountStatus.success) {
          HelperFunctions.showMessage(
            context,
            translateGlAccountBlocMessage(state.message, _localizations),
            Colors.green,
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            popUpDialog(
              context: context,
              title: _localizations.initialUpload,
              children: [
                const SizedBox(height: 40),
                Text(_localizations.downloadFirst),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('periodYear'),
                  controller: _periodYearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _localizations.accountingPeriodYear,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('upload'),
                  child: Text(_localizations.uploadCsv),
                  onPressed: () async {
                    final periodYear = _periodYearController.text.trim();
                    if (!RegExp(r'^\d{4}$').hasMatch(periodYear)) {
                      HelperFunctions.showMessage(
                        context,
                        _localizations.accountingPeriodYearError,
                        Colors.red,
                      );
                      return;
                    }
                    PlatformFile? picked = await FilePicker.pickFile(
                      allowedExtensions: ['csv'],
                      type: FileType.custom,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final fileString = String.fromCharCodes(bytes);
                      glAccountBloc.add(
                        GlAccountUpload(fileString, periodYear),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('download'),
                  child: Text(_localizations.downloadCsv),
                  onPressed: () {
                    glAccountBloc.add(GlAccountDownload());
                  },
                ),
              ],
            ),
            if (state.status == GlAccountStatus.loading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}
