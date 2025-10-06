import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:growerp_order_accounting/src/findoc/blocs/invoice_upload/invoice_upload_bloc.dart';
import 'dart:convert';

class InvoiceUploadView extends StatefulWidget {
  const InvoiceUploadView({super.key});

  @override
  State<InvoiceUploadView> createState() => _InvoiceUploadViewState();
}

class _InvoiceUploadViewState extends State<InvoiceUploadView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  Map<String, dynamic>? _extractedData;

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  void _uploadImage() {
    if (_imageFile == null) {
      return;
    }
    context.read<InvoiceUploadBloc>().add(InvoiceUploadImage(
          image: _imageFile!,
          prompt:
              "Extract invoice data as a JSON object with fields: 'supplier', 'invoiceDate', and 'items' (an array with 'description', 'quantity', 'unitPrice').",
          mimeType: 'image/jpeg',
        ));
  }

  void _createInvoice() {
    if (_extractedData == null) {
      return;
    }
    context.read<InvoiceUploadBloc>().add(InvoiceCreate(_extractedData!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Invoice'),
      ),
      body: BlocListener<InvoiceUploadBloc, InvoiceUploadState>(
        listener: (context, state) {
          if (state.status == InvoiceUploadStatus.failure) {
            HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          }
          if (state.status == InvoiceUploadStatus.success) {
            if (state.extractedData != null) {
              setState(() {
                _extractedData = state.extractedData;
              });
              HelperFunctions.showMessage(
                  context, 'Image processed successfully!', Colors.green);
            }
            if (state.invoice != null) {
              Navigator.of(context).pop();
              HelperFunctions.showMessage(
                  context, 'Invoice created successfully!', Colors.green);
            }
          }
        },
        child: BlocBuilder<InvoiceUploadBloc, InvoiceUploadState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_imageFile != null)
                      Image.file(
                        File(_imageFile!.path),
                        height: 200,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Pick Image'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _imageFile != null ? _uploadImage : null,
                      child: const Text('Upload and Process'),
                    ),
                    if (state.status == InvoiceUploadStatus.loading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    if (_extractedData != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          const JsonEncoder.withIndent('  ')
                              .convert(_extractedData),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _extractedData != null ? _createInvoice : null,
                      child: const Text('Create Invoice'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}