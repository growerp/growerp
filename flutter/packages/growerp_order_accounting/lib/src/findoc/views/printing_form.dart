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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../findoc.dart';

class PrintingForm extends StatelessWidget {
  final FinDoc finDocIn;
  const PrintingForm({super.key, required this.finDocIn});

  Future<void> _emailInvoice(
    BuildContext context,
    Company company,
    FinDoc finDoc,
  ) async {
    final emailController = TextEditingController(
      text: finDoc.otherCompany?.email ?? finDoc.otherUser?.email ?? '',
    );
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Email ${finDoc.docType?.name ?? 'document'}'),
        content: TextField(
          key: const Key('emailInvoiceTo'),
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Send to'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            key: const Key('cancelEmailInvoice'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmEmailInvoice'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a recipient email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final restClient = context.read<RestClient>();
    try {
      final bytes = await PdfFormats.finDocPdf(
        PdfPageFormat.a4,
        company,
        finDoc,
      );
      await restClient.sendFinDocEmail(
        finDocId: finDoc.id()!,
        pdfBase64: base64Encode(bytes),
        toEmail: emailController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emailed to ${emailController.text.trim()}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      if (finDoc.docType == FinDocType.order ||
                          finDoc.docType == FinDocType.invoice)
                        SizedBox(
                          height: 100,
                          child: OutlinedButton(
                            key: const Key('emailInvoice'),
                            child: const Icon(Icons.email),
                            onPressed: () => _emailInvoice(
                              context,
                              authenticate.company!,
                              finDoc,
                            ),
                          ),
                        ),
                    ],
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
