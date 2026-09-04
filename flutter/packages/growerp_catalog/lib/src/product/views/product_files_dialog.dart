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

class ProductFilesDialog extends StatefulWidget {
  const ProductFilesDialog({super.key});

  @override
  State<ProductFilesDialog> createState() => _FilesHeaderState();
}

class _FilesHeaderState extends State<ProductFilesDialog> {
  late ProductBloc productBloc;
  @override
  void initState() {
    productBloc = BlocProvider.of<ProductBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var catalogLocalizations = CatalogLocalizations.of(context)!;
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) async {
        if (state.status == ProductStatus.failure) {
          HelperFunctions.showMessage(
            context,
            catalogLocalizations.error(state.message ?? ''),
            Colors.red,
          );
        }
        if (state.status == ProductStatus.success) {
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
              title: catalogLocalizations.productFiles,
              children: [
                const SizedBox(height: 40),
                Text(catalogLocalizations.downloadFormat),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('upload'),
                  child: Text(catalogLocalizations.uploadCsv),
                  onPressed: () async {
                    PlatformFile? picked = await FilePicker.pickFile(
                      allowedExtensions: ['csv'],
                      type: FileType.custom,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final fileString = String.fromCharCodes(bytes);
                      productBloc.add(ProductUpload(fileString));
                    }
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('download'),
                  child: Text(catalogLocalizations.downloadEmail),
                  onPressed: () {
                    productBloc.add(ProductDownload());
                  },
                ),
                const SizedBox(height: 20),
                Text(catalogLocalizations.emailData),
              ],
            ),
            if (state.status == ProductStatus.loading) const LoadingIndicator(),
          ],
        );
      },
    );
  }
}
