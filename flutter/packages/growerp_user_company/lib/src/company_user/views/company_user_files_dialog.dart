import 'package:universal_io/io.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;

import '../../../l10n/generated/user_company_localizations.dart';
import '../../common/translate_bloc_messages.dart';
import '../company_user.dart';

class CompanyUserFilesDialog extends StatefulWidget {
  const CompanyUserFilesDialog({super.key});

  @override
  State<CompanyUserFilesDialog> createState() => _CompanyUserFilesDialogState();
}

class _CompanyUserFilesDialogState extends State<CompanyUserFilesDialog> {
  late CompanyUserBloc companyUserBloc;
  @override
  void initState() {
    companyUserBloc = BlocProvider.of<CompanyUserBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = UserCompanyLocalizations.of(context)!;
    return BlocConsumer<CompanyUserBloc, CompanyUserState>(
      listener: (context, state) async {
        if (state.status == CompanyUserStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == CompanyUserStatus.success) {
          final translatedMessage = state.message != null
              ? translateUserCompanyBlocMessage(localizations, state.message!)
              : '';
          if (translatedMessage.isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              translatedMessage,
              Colors.green,
            );
          }
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            popUpDialog(
              context: context,
              title: "CompanyUser Up/Download",
              children: [
                const SizedBox(height: 40),
                const Text("Download first to obtain the format"),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('upload'),
                  child: const Text('Upload CSV file'),
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
                      companyUserBloc.add(CompanyUserUpload(fileString));
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        companyUserBloc.add(
                          const CompanyUserFetch(refresh: true),
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('download'),
                  child: const Text('Download via email'),
                  onPressed: () {
                    companyUserBloc.add(CompanyUserDownload());
                  },
                ),
                const SizedBox(height: 20),
                const Text("A data file will be send by email"),
              ],
            ),
            if (state.status == CompanyUserStatus.filesLoading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}
