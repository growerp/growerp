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

import '../product.dart';

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
    return BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) async {
      if (state.status == ProductStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
      if (state.status == ProductStatus.success) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        Navigator.of(context).pop();
      }
    }, builder: (context, state) {
      return Stack(children: [
        popUpDialog(context: context, title: "Product Up/Download", children: [
          const SizedBox(height: 40),
          const Text("Download first to obtain the format"),
          const SizedBox(height: 10),
          OutlinedButton(
              key: const Key('upload'),
              child: const Text('Upload CSV file'),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowedExtensions: ['csv'], type: FileType.custom);
                if (result != null) {
                  String fileString = '';
                  if (foundation.kIsWeb) {
                    foundation.Uint8List bytes = result.files.first.bytes!;
                    fileString = String.fromCharCodes(bytes);
                  } else {
                    File file = File(result.files.single.path!);
                    fileString = await file.readAsString();
                  }
                  productBloc.add(ProductUpload(fileString));
                }
              }),
          const SizedBox(height: 20),
          OutlinedButton(
              key: const Key('download'),
              child: const Text('Download via email'),
              onPressed: () {
                productBloc.add(ProductDownload());
              }),
          const SizedBox(height: 20),
          const Text("A data file will be send by email"),
        ]),
        if (state.status == ProductStatus.filesLoading)
          const LoadingIndicator(),
      ]);
    });
  }
}
