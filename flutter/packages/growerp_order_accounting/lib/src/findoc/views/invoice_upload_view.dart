import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:growerp_order_accounting/src/findoc/blocs/invoice_upload/invoice_upload_bloc.dart';
import 'package:image_picker/image_picker.dart';

class InvoiceUploadView extends StatefulWidget {
  const InvoiceUploadView({super.key});

  @override
  State<InvoiceUploadView> createState() => _InvoiceUploadViewState();
}

class _InvoiceUploadViewState extends State<InvoiceUploadView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  Uint8List? _imageBytes;
  Map<String, dynamic>? _extractedData;
  OrderAccountingLocalizations? _localizations;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = imageBytes;
      });
    }
  }

  void _uploadImage() {
    if (_imageFile == null) {
      return;
    }
    context.read<InvoiceUploadBloc>().add(
      InvoiceUploadImage(
        image: _imageFile!,
        prompt:
            "Extract invoice data as a JSON object with fields: 'supplier', 'invoiceDate', and 'items' (an array with 'description', 'quantity', 'unitPrice').",
        mimeType: 'image/jpeg',
      ),
    );
  }

  void _createInvoice() {
    if (_extractedData == null) {
      return;
    }
    context.read<InvoiceUploadBloc>().add(InvoiceCreate(_extractedData!));
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocListener<InvoiceUploadBloc, InvoiceUploadState>(
          listener: (context, state) {
            if (state.status == InvoiceUploadStatus.failure) {
              HelperFunctions.showMessage(
                context,
                '${state.message}',
                Colors.red,
              );
            }
            if (state.status == InvoiceUploadStatus.success) {
              if (state.extractedData != null) {
                setState(() {
                  _extractedData = state.extractedData;
                });
                HelperFunctions.showMessage(
                  context,
                  _localizations!.imageProcessed,
                  Colors.green,
                );
              }
              if (state.invoice != null) {
                Navigator.of(context).pop();
                HelperFunctions.showMessage(
                  context,
                  _localizations!.invoiceCreated,
                  Colors.green,
                );
              }
            }
          },
          child: Dialog(
            key: const Key('InvoiceUploadDialog'),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: popUp(
              context: context,
              title: _localizations!.uploadInvoice,
              height: 600,
              width: 500,
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return BlocBuilder<InvoiceUploadBloc, InvoiceUploadState>(
      builder: (context, state) {
        if (state.status == InvoiceUploadStatus.loading) {
          return const Center(child: LoadingIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_imageFile != null && _imageBytes != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('pickImage'),
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _imageFile == null
                      ? _localizations!.pickImage
                      : _localizations!.changeImage,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('processImage'),
                onPressed: _imageFile != null ? _uploadImage : null,
                icon: const Icon(Icons.cloud_upload),
                label: Text(_localizations!.uploadAndProcess),
              ),
              if (_extractedData != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  _localizations!.extractedData,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(_extractedData),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('createInvoice'),
                  onPressed: _createInvoice,
                  icon: const Icon(Icons.check),
                  label: Text(_localizations!.createInvoice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
