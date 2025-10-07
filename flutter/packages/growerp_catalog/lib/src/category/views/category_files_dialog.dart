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

import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' as foundation;

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
