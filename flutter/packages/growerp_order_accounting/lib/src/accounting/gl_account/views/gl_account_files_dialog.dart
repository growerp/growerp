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

import '../gl_account.dart';

final GlobalKey<ScaffoldMessengerState> glAccountFilesDialogKey =
    GlobalKey<ScaffoldMessengerState>();

class GlAccountFilesDialog extends StatefulWidget {
  const GlAccountFilesDialog({super.key});

  @override
  State<GlAccountFilesDialog> createState() => _FilesHeaderState();
}

class _FilesHeaderState extends State<GlAccountFilesDialog> {
  late GlAccountBloc glAccountBloc;
  @override
  void initState() {
    glAccountBloc = BlocProvider.of<GlAccountBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GlAccountBloc, GlAccountState>(
        listener: (context, state) async {
      if (state.status == GlAccountStatus.failure) {
        glAccountFilesDialogKey.currentState!
            .showSnackBar(snackBar(context, Colors.red, state.message ?? ''));
      }
      if (state.status == GlAccountStatus.success) {
        glAccountFilesDialogKey.currentState!
            .showSnackBar(snackBar(context, Colors.green, state.message ?? ''));
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    }, builder: (context, state) {
      return Stack(children: [
        popUpDialog(
            scaffoldkey: glAccountFilesDialogKey,
            context: context,
            title: "GlAccount Up/Download",
            children: [
              const SizedBox(height: 40),
              const Text("Download first to obtain the format"),
              const SizedBox(height: 10),
              ElevatedButton(
                  key: const Key('upload'),
                  child: const Text('Upload CSV file'),
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
                      glAccountBloc.add(GlAccountUpload(fileString));
                    }
                  }),
              const SizedBox(height: 20),
              ElevatedButton(
                  key: const Key('download'),
                  child: const Text('Download via email'),
                  onPressed: () {
                    glAccountBloc.add(GlAccountDownload());
                  }),
              const SizedBox(height: 20),
              const Text("A data file will be send by email"),
            ]),
        if (state.status == GlAccountStatus.loading) const LoadingIndicator(),
      ]);
    });
  }
}
