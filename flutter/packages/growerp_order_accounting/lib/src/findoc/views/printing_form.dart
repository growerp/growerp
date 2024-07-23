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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../findoc.dart';

class PrintingForm extends StatelessWidget {
  final FinDoc finDocIn;
  const PrintingForm({super.key, required this.finDocIn});

  @override
  Widget build(BuildContext context) {
    late Authenticate authenticate;

    return BlocProvider<FinDocBloc>(
        create: (context) => FinDocBloc(context.read<RestClient>(),
            finDocIn.sales, finDocIn.docType!, context.read<String>())
          ..add(FinDocFetch(
              finDocId: finDocIn.id()!, docType: finDocIn.docType!)),
        child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            authenticate = state.authenticate!;
          }
          return Stack(children: [
            PdfPreview(
              build: (format) =>
                  PdfFormats.finDocPdf(format, authenticate.company!, finDocIn),
            ),
            SizedBox(
                height: 100,
                child: OutlinedButton(
                    key: const Key('back'),
                    child: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pop();
                    })),
          ]);
        }));
  }
}
