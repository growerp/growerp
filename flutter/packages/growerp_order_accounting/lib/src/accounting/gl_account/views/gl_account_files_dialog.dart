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

import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../gl_account.dart';

class GlAccountFilesDialog extends StatefulWidget {
  const GlAccountFilesDialog({super.key});

  @override
  State<GlAccountFilesDialog> createState() => _FilesHeaderState();
}

class _FilesHeaderState extends State<GlAccountFilesDialog> {
  late GlAccountBloc glAccountBloc;
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    glAccountBloc = BlocProvider.of<GlAccountBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    return BlocConsumer<GlAccountBloc, GlAccountState>(
      listener: (context, state) async {
        if (state.status == GlAccountStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == GlAccountStatus.success) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
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
              title: _localizations.glAccountUpDown,
              children: [
                const SizedBox(height: 40),
                Text(_localizations.downloadFirst),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('upload'),
                  child: Text(_localizations.uploadCsv),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                          allowedExtensions: ['csv'],
                          type: FileType.custom,
                        );
                    if (result != null) {
                      String fileString = '';
                      if (foundation.kIsWeb) {
                        foundation.Uint8List bytes = result.files.first.bytes!;
                        fileString = String.fromCharCodes(bytes);
                      } else {
                        File file = File(result.files.single.path!);
                        fileString = await file.readAsString();
                      }
                      glAccountBloc.add(GlAccountUpload(fileString));
                    }
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('download'),
                  child: Text(_localizations.downloadEmail),
                  onPressed: () {
                    glAccountBloc.add(GlAccountDownload());
                  },
                ),
                const SizedBox(height: 20),
                Text(_localizations.dataFileSendEmail),
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
