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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

import '../bloc/master_content_bloc.dart';
import '../bloc/master_content_event.dart';
import '../bloc/master_content_state.dart';

/// Up/download of all master content with its images as a ZIP file.
class MasterContentFilesDialog extends StatelessWidget {
  const MasterContentFilesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = MarketingLocalizations.of(context)!;
    final bloc = context.read<MasterContentBloc>();
    return BlocConsumer<MasterContentBloc, MasterContentState>(
      listener: (context, state) async {
        if (state.status == MasterContentStatus.failure) {
          HelperFunctions.showMessage(
              context, state.message ?? 'Error', Colors.red);
        }
        if (state.status != MasterContentStatus.success) return;
        final file = state.exportFile;
        if (file != null) {
          // the export is in: let the user save it, keep the dialog open
          await FilePicker.saveFile(
            dialogTitle: localizations.downloadZip,
            fileName: file.name,
            type: FileType.custom,
            allowedExtensions: ['zip'],
            bytes: file.bytes,
          );
        } else if ((state.message ?? '').isNotEmpty && context.mounted) {
          // the import is done (the list shows its message)
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) => Stack(
        children: [
          popUpDialog(
            context: context,
            title: localizations.masterContentFiles,
            children: [
              const SizedBox(height: 20),
              Text(localizations.masterContentFilesInfo),
              const SizedBox(height: 20),
              OutlinedButton(
                key: const Key('upload'),
                child: Text(localizations.uploadZip),
                onPressed: () async {
                  final picked = await FilePicker.pickFile(
                    type: FileType.custom,
                    allowedExtensions: ['zip'],
                  );
                  if (picked == null) return;
                  bloc.add(MasterContentImport(await picked.readAsBytes()));
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                key: const Key('download'),
                child: Text(localizations.downloadZip),
                onPressed: () => bloc.add(const MasterContentExport()),
              ),
            ],
          ),
          if (state.status == MasterContentStatus.loading)
            const LoadingIndicator(),
        ],
      ),
    );
  }
}
