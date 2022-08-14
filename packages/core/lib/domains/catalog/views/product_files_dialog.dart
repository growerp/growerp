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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:core/domains/domains.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' as foundation;

final GlobalKey<ScaffoldMessengerState> ProductFilesDialogKey =
    GlobalKey<ScaffoldMessengerState>();

class ProductFilesDialog extends StatefulWidget {
  @override
  State<ProductFilesDialog> createState() => _FilesHeaderState();
}

class _FilesHeaderState extends State<ProductFilesDialog> {
  late ProductBloc _ProductBloc;
  @override
  void initState() {
    _ProductBloc = BlocProvider.of<ProductBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) async {
      if (state.status == ProductStatus.failure)
        ProductFilesDialogKey.currentState!
            .showSnackBar(snackBar(context, Colors.red, state.message ?? ''));
      if (state.status == ProductStatus.success) {
        ProductFilesDialogKey.currentState!
            .showSnackBar(snackBar(context, Colors.green, state.message ?? ''));
        await Future.delayed(Duration(milliseconds: 1000));
        Navigator.of(context).pop();
      }
    }, builder: (context, state) {
      return Stack(children: [
        PopUpDialog(
            scaffoldkey: ProductFilesDialogKey,
            context: context,
            title: "Product Up/Download",
            children: [
              SizedBox(height: 40),
              Text("Download first to obtain the format"),
              SizedBox(height: 10),
              ElevatedButton(
                  key: Key('upload'),
                  child: Text('Upload CSV file'),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
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
                      _ProductBloc.add(ProductUpload(fileString));
                    }
                  }),
              SizedBox(height: 20),
              ElevatedButton(
                  key: Key('download'),
                  child: Text('Download via email'),
                  onPressed: () {
                    _ProductBloc.add(ProductDownload());
                  }),
              SizedBox(height: 20),
              Text("A data file will be send by email"),
            ]),
        if (state.status == ProductStatus.filesLoading) LoadingIndicator(),
      ]);
    });
  }
}
