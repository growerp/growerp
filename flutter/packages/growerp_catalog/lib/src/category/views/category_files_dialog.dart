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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../growerp_catalog.dart';

class CategoryFilesDialog extends StatefulWidget {
  const CategoryFilesDialog({super.key});

  @override
  State<CategoryFilesDialog> createState() => _FilesHeaderState();
}

class _FilesHeaderState extends State<CategoryFilesDialog> {
  late CategoryBloc _categoryBloc;
  CatalogLocalizations? _localizations;
  @override
  void initState() {
    _categoryBloc = BlocProvider.of<CategoryBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = CatalogLocalizations.of(context);
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) async {
        if (state.status == CategoryStatus.failure) {
          HelperFunctions.showMessage(
            context,
            _localizations!.error(state.message ?? ''),
            Colors.red,
          );
        }
        if (state.status == CategoryStatus.success) {
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
              title: _localizations!.categoryFiles,
              children: [
                const SizedBox(height: 40),
                Text(_localizations!.downloadFormat),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('upload'),
                  child: Text(_localizations!.uploadCsv),
                  onPressed: () async {
                    PlatformFile? picked = await FilePicker.pickFile(
                      allowedExtensions: ['csv'],
                      type: FileType.custom,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final fileString = String.fromCharCodes(bytes);
                      _categoryBloc.add(CategoryUpload(fileString));
                    }
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('download'),
                  child: Text(_localizations!.downloadEmail),
                  onPressed: () {
                    _categoryBloc.add(CategoryDownload());
                  },
                ),
                const SizedBox(height: 20),
                Text(_localizations!.emailData),
              ],
            ),
            if (state.status == CategoryStatus.loading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}
