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
      create: (context) => FinDocBloc(
        context.read<RestClient>(),
        finDocIn.sales,
        finDocIn.docType!,
        context.read<String>(),
      )..add(FinDocFetch(finDocId: finDocIn.id()!, docType: finDocIn.docType!)),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.authenticated) {
            authenticate = authState.authenticate!;
          }
          return BlocBuilder<FinDocBloc, FinDocState>(
            builder: (context, finDocState) {
              if (finDocState.status == FinDocStatus.loading ||
                  finDocState.status == FinDocStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              final finDoc = finDocState.finDoc ?? finDocIn;
              return Stack(
                children: [
                  PdfPreview(
                    build: (format) => PdfFormats.finDocPdf(
                      format,
                      authenticate.company!,
                      finDoc,
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: OutlinedButton(
                      key: const Key('back'),
                      child: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
