import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
                Text(UserCompanyLocalizations.of(context)!.downloadFirstToObtainTheFormat),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('upload'),
                  child: Text(UserCompanyLocalizations.of(context)!.uploadCsvFile),
                  onPressed: () async {
                    PlatformFile? picked = await FilePicker.pickFile(
                      allowedExtensions: ['csv'],
                      type: FileType.custom,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final fileString = String.fromCharCodes(bytes);
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
                  child: Text(UserCompanyLocalizations.of(context)!.downloadViaEmail),
                  onPressed: () {
                    companyUserBloc.add(CompanyUserDownload());
                  },
                ),
                const SizedBox(height: 20),
                Text(UserCompanyLocalizations.of(context)!.aDataFileWillBeSendByEmail),
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
