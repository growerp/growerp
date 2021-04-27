/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:core/forms/@forms.dart';
import 'package:core/helper_functions.dart';
import 'package:core/widgets/@widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'pdfFormats.dart';

class PrintingForm extends StatelessWidget {
  final FormArguments formArguments;
  const PrintingForm({Key? key, required this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PrintingPage(finDocIn: formArguments.object as FinDoc);
  }
}

class PrintingPage extends StatelessWidget {
  final FinDoc finDocIn;
  const PrintingPage({Key? key, required this.finDocIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late Authenticate authenticate;
    FinDoc finDoc = FinDoc();

    var repos = context.read<Object>();
    return BlocProvider<FinDocBloc>(
        create: (context) =>
            FinDocBloc(repos, finDocIn.sales!, finDocIn.docType!)
              ..add(FetchFinDoc(id: finDocIn.id(), docType: finDocIn.docType)),
        child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
          if (state is AuthAuthenticated) authenticate = state.authenticate!;
          return BlocConsumer<FinDocBloc, FinDocState>(
              listener: (context, state) {
            if (state is FinDocProblem)
              HelperFunctions.showMessage(
                  context, '${state.errorMessage}', Colors.red);
            if (state is FinDocSuccess) {
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
            }
            if (state is FinDocLoading)
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
          }, builder: (context, state) {
            if (state is FinDocProblem)
              return FatalErrorForm("problem loading docs");
            if (state is FinDocLoading) return LoadingIndicator();
            if (state is FinDocSuccess) {
              finDoc = state.finDocs![0];
              return PdfPreview(
                build: (format) =>
                    PdfFormats.finDocPdf(format, authenticate.company!, finDoc),
              );
            }
            return Container();
          });
        }));
  }
}
